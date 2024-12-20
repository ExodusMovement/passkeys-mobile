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
    @ObservedObject var viewModel: WebViewModel

    var body: some View {
        var delegate = WebviewDelegate()

        return Webview(
            url: URL(string: "https://wallet-d.passkeys.foundation?relay")!,
            uiDelegate: delegate,
            onWebViewCreated: { webView in
                self.viewModel.webView = webView
            }
        )
        .ignoresSafeArea()
        .navigationTitle("Passkeys")
        .navigationBarTitleDisplayMode(.inline)
    }

    public func callAsyncJavaScript(_ script: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let webviewInstance = viewModel.webView else {
            print("test evaluating JS missing webview instance", viewModel.webView)
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
                        // Handle "null" or "undefined" string cases
                        if jsResult == "null" || jsResult == "undefined" {
                            completion(.success(nil))
                            return
                        }

                        // Convert the string to Data for JSON parsing
                        if let jsonData = jsResult.data(using: .utf8) {
                            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
                            completion(.success(jsonObject))
                        } else {
                            completion(.failure(CustomError.message("invalid format")))
                        }
                    } else {
                        completion(.failure(CustomError.message("invalid format")))
                    }
                } catch {
                    completion(.failure(error))
                }
            } catch {
                print("JavaScript execution failed:", error.localizedDescription)
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

        let script = """
        const result = window.\(method)(\(dataJSON));
        if (result instanceof Promise) {
            return result
                .then(resolved => {
                    console.log('Async Promise resolved:', resolved);
                    return JSON.stringify(resolved); // Return resolved value directly
                })
                .catch(error => {
                    console.error('Async Promise rejected:', error);
                    throw error; // Throw error to propagate to Swift
                });
        } else {
            console.log('Sync result:', result);
            return JSON.stringify(resolved); // Return sync result directly
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
