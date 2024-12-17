import SafariServices
import WebKit
import SwiftUI

class WebViewModel: ObservableObject {
    @Published var webView: WKWebView? = nil
}

enum CustomError: Error {
    case message(String)
}

struct PasskeysMobile: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String
    @ObservedObject var viewModel: WebViewModel


    var body: some View {
        let delegate: WebviewDelegate? = WebviewDelegate()

        if let delegate = delegate {
            return Webview(
                url: URL(string: embeddedWalletUrl)!,
                uiDelegate: delegate,
                onWebViewCreated: { webView in
                    self.viewModel.webView = webView
                }
            )
            .ignoresSafeArea()
            .navigationTitle("Passkeys")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            return Text("Error: Delegate not initialized")
        }
    }

    public func callAsyncJavaScript(_ script: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let webviewInstance = viewModel.webView else {
            completion(.failure(CustomError.message("Didn't find WebView")))
            return
        }

        Task {
            do {
                let jsResult = try await webviewInstance.callAsyncJavaScript(
                    script,
                    arguments: [:],
                    contentWorld: .page
                )

                do {
                    if let jsResult = jsResult as? String {
                        if jsResult == "null" || jsResult == "undefined" {
                            completion(.success(nil)) // todo throw instead?
                            return
                        }

                        if let jsonData = jsResult.data(using: .utf8) {
                            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
                            completion(.success(jsonObject))
                        } else {
                            completion(.failure(CustomError.message("invalid response json format")))
                        }
                    } else {
                        completion(.failure(CustomError.message("invalid response format")))
                    }
                } catch {
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func callMethod(_ method: String, data: [String: Any]?, completion: @escaping (Result<Any?, Error>) -> Void) {
        let dataJSON: String
        if let data = data,
           let dataString = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: dataString, encoding: .utf8) {
            dataJSON = jsonString
        } else {
            dataJSON = ""
        }

        // stringify before returning to swift to handle buffers, which swift interprets differently than we expect
        let script = """
        const result = window.\(method)(\(dataJSON));
        if (result instanceof Promise) {
            return result
                .then(resolved => {
                    return JSON.stringify(resolved);
                })
                .catch(error => {
                    throw error;
                });
        } else {
            return JSON.stringify(resolved);
        }
        """
        callAsyncJavaScript(script, completion: completion)
    }
}


struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDismiss()
        }
    }
}

class WebviewDelegate: NSObject, WKUIDelegate {
    private weak var hostingController: UIViewController?

    func presentSafariView(from ctrl: UIViewController, url: URL) {
        let safariView = SafariView(
            url: url,
            onDismiss: {
                ctrl.dismiss(animated: true)
                self.hostingController = nil
            }
        )
        let hostingController = UIHostingController(rootView: safariView)
        self.hostingController = hostingController
        ctrl.present(hostingController, animated: true)
    }

    func closeSafariView() {
        hostingController?.dismiss(animated: true, completion: {
            self.hostingController = nil
        })
    }

    func openSafariView(url: String) {
        if let ctrl = RCTPresentedViewController() {
            presentSafariView(from: ctrl, url: URL(string: url)!)
        } else {
            print("Failed to retrieve presented view controller.")
        }
    }
}
