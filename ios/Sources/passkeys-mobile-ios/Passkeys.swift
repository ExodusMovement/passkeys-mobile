import SafariServices
import WebKit
import SwiftUI

public class WebViewModel: ObservableObject {
    @Published var webView: WKWebView? = nil
    @Published public var url: String? = nil
    @Published public var appId: String? = nil
    @Published public var isLoading: Bool = true
    @Published public var loadingErrorMessage: String? = nil

    public init() {}
}

public enum CustomError: Error, LocalizedError {
    case message(String)

    public var errorDescription: String? {
        switch self {
        case .message(let msg):
            return msg
        }
    }
}

public struct Passkeys: View {
    @ObservedObject public var viewModel: WebViewModel

    public init(appId: String?, url: String? = nil, viewModel: WebViewModel = WebViewModel()) {
        self.viewModel = viewModel

        DispatchQueue.main.async {
            viewModel.url = url
            viewModel.appId = appId
        }
    }

    public var body: some View {
        let delegate = WebviewDelegate()
        let baseURLString = viewModel.url ?? "https://relay.passkeys.network"
        let fullURLString = "\(baseURLString)?appId=\(viewModel.appId ?? "")"

        Group {
            if viewModel.appId != nil  {
                if let url = URL(string: fullURLString) {
                    Webview(
                        url: url,
                        uiDelegate: delegate,
                        onWebViewCreated: { webView in
                            self.viewModel.webView = webView
                        },
                        onLoadingEnd: { loading, error in
                            self.viewModel.isLoading = loading
                            self.viewModel.loadingErrorMessage = error
                        }
                    )
                    .ignoresSafeArea()
                    .navigationTitle("Passkeys")
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Error: Invalid URL")
                }
            }
            else {
                Text("Error: missing appId")
            }
        }
        .onAppear {
            self.viewModel.loadingErrorMessage = nil
            self.viewModel.isLoading = true
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
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    if let noMethod = jsonObject["noMethod"] as? Bool, noMethod {
                        completion(.failure(CustomError.message("Method not defined")))
                    } else if  let isError = jsonObject["isError"] as? Bool, isError {
                        if let errorMessage = jsonObject["error"] as? String {
                            completion(.failure(CustomError.message(errorMessage)))
                        } else {
                            completion(.failure(CustomError.message("Unknown JavaScript Error")))
                        }
                    } else {
                        completion(.success(jsonObject))
                    }
                } else {
                    completion(.failure(CustomError.message("Invalid JavaScript response format")))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func callMethod(_ method: String, data: [String: Any]?, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard viewModel.appId != nil else {
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
        if (!window.passkeys || !window.passkeys.\(method)) return JSON.stringify({noMethod: true});
        let result;
        try {
            result = window.passkeys.\(method)(\(dataJSON));
        }
        catch (error) {
            return JSON.stringify({isError: true, error: error && (error.message || String(error))})
        }

        if (result instanceof Promise) {
            return result
                .then(resolved => JSON.stringify(resolved))
                .catch(error => JSON.stringify({isError: true, error: error && (error.message || String(error))}));
        } else {
            try {
                return JSON.stringify(result);
            }
            catch (error) {
                return JSON.stringify({isError: true, error: error && (error.message || String(error))});
            }
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
        if let ReactNativeControllerClass = NSClassFromString("RCTPresentedViewController") as? UIViewController.Type {
            let reactNativeController = ReactNativeControllerClass.init()
            return reactNativeController
        }

        var topController: UIViewController? {
            if #available(iOS 15.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                    return nil
                }
                return windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            } else {
                return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
            }
        }
        var currentController = topController

        while let presentedController = currentController?.presentedViewController {
            currentController = presentedController
        }
        return currentController
    }

    func openSafariView(url: String) {
        guard let viewController = getPresentedViewController() else {
            print("Failed to retrieve presented view controller.")
            return
        }
        guard let safariURL = URL(string: url),
              let scheme = safariURL.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            print("Invalid URL.")
            return
        }
        presentSafariView(from: viewController, url: safariURL)
    }
}
