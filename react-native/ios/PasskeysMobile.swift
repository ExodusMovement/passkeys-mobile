import SafariServices
import WebKit
import SwiftUI

class WebViewModel: ObservableObject {
    @Published var webView: WKWebView? = nil
    @Published var url: String? = nil
    @Published var appId: String? = nil
    public init() {}
}

enum CustomError: Error {
    case message(String)
}

public struct PasskeysMobileView: View {
    @ObservedObject var viewModel: WebViewModel

    public init(appId: String?, url: String? = nil) {
        self.viewModel = WebViewModel()
        self.viewModel.url = url
        self.viewModel.appId = appId
    }

    public var body: some View {
        let delegate = WebviewDelegate()
        let baseURLString = viewModel.url ?? "https://signer-relay-d.passkeys.foundation"
        let fullURLString = "\(baseURLString)?appId=\(viewModel.appId as? String ?? "")"

        Group {
            if let url = URL(string: fullURLString) {
                Webview(
                    url: url,
                    uiDelegate: delegate,
                    onWebViewCreated: { webView in
                        self.viewModel.webView = webView
                    }
                )
                .ignoresSafeArea()
                .navigationTitle("Passkeys")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Error: Invalid URL")
            }
        }
    }

    public func callAsyncJavaScript(_ script: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let webviewInstance = viewModel.webView else {
            completion(.failure(CustomError.message("WebView not found")))
            return
        }

        Task {
            do {
                let jsResult = try await webviewInstance.callAsyncJavaScript(
                    script,
                    arguments: [:],
                    contentWorld: .page
                )

                if jsResult == nil || jsResult is NSNull {
                    completion(.success(nil))
                } else if let jsResult = jsResult as? String,
                   let jsonData = jsResult.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) {
                    completion(.success(jsonObject))
                } else {
                    completion(.failure(CustomError.message("Invalid JavaScript response format")))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func callMethod(_ method: String, data: [String: Any]?, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let appId = viewModel.appId else {
            completion(.failure(CustomError.message("appId cannot be null")))
            return
        }
        let dataJSON: String
        if let data = data,
           let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            dataJSON = jsonString
        } else {
            dataJSON = "{}"
        }

        let script = """
        const result = window.\(method)(\(dataJSON));
        if (result instanceof Promise) {
            return result
                .then(resolved => JSON.stringify(resolved))
                .catch(error => { throw error; });
        } else {
            return JSON.stringify(result);
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

    func presentSafariView(from viewController: UIViewController, url: URL) {
        let safariView = SafariView(url: url, onDismiss: {
            viewController.dismiss(animated: true)
            self.hostingController = nil
        })
        let hostingController = UIHostingController(rootView: safariView)
        self.hostingController = hostingController
        viewController.present(hostingController, animated: true)
    }

    func closeSafariView() {
        hostingController?.dismiss(animated: true) {
            self.hostingController = nil
        }
    }

    func getPresentedViewController() -> UIViewController? {
        if let reactNativeController = (NSClassFromString("RCTPresentedViewController") as? () -> UIViewController)?() {
            return reactNativeController
        }

        var topController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }

    func openSafariView(url: String) {
        guard let viewController = getPresentedViewController(),
              let safariURL = URL(string: url) else {
            print("Failed to retrieve presented view controller or invalid URL.")
            return
        }
        presentSafariView(from: viewController, url: safariURL)
    }
}
