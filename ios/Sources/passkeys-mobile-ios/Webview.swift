import WebKit
import SwiftUI

struct Webview: UIViewRepresentable {
    let url: URL
    let uiDelegate: WebviewDelegate
    var onWebViewCreated: ((WKWebView) -> Void)?
    var onLoadingEnd: ((Bool, String?) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "closeSigner")
        contentController.add(context.coordinator, name: "openSigner")
        contentController.add(context.coordinator, name: "onLoadingEnd")
        configuration.userContentController = contentController

        let js = """
        if (!window.nativeBridge) {
            window.nativeBridge = {};
        }
        window.nativeBridge.closeSigner = function() {
            window.webkit.messageHandlers.closeSigner.postMessage(null);
        };
        window.nativeBridge.openSigner = function(url) {
            if (typeof url !== 'string') throw new Error('url is not a string');
            window.webkit.messageHandlers.openSigner.postMessage(url);
        };
        window.nativeBridge.onLoadingEnd = function(loading, error) {
            window.webkit.messageHandlers.onLoadingEnd.postMessage({ loading: loading, error: error ? String(error) : null });
        };
        """
        contentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = uiDelegate

        webView.load(URLRequest(url: url))

        DispatchQueue.main.async {
            self.onWebViewCreated?(webView)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        DispatchQueue.main.async {
            self.onWebViewCreated?(webView)
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: Webview

        init(_ parent: Webview) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "closeSigner" {
                DispatchQueue.main.async {
                    self.parent.uiDelegate.closeSafariView()
                }
            }
            if message.name == "openSigner" {
                if let url = message.body as? String {
                    DispatchQueue.main.async {
                        self.parent.uiDelegate.openSafariView(url: url)
                    }
                } else {
                    print("url is not a String")
                }
            }
            if message.name == "onLoadingEnd" {
                if let body = message.body as? [String: Any],
                   let loading = body["loading"] as? Bool {
                    let error: String? = body["error"] is NSNull ? nil : body["error"] as? String
                    DispatchQueue.main.async {
                        self.parent.onLoadingEnd?(loading, error)
                    }
                }
            }
        }
    }
}
