import WebKit
import SwiftUI

struct Webview: UIViewRepresentable {
    let url: URL
    let uiDelegate: WebviewDelegate
    var onWebViewCreated: ((WKWebView) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "closeSigner")
        configuration.userContentController = contentController

        let js = """
        if (!window.uiControl) {
            window.uiControl = {};
        }
        window.uiControl.closeSigner = function() {
            window.webkit.messageHandlers.closeSigner.postMessage(null);
        };
        const readyEvent = new Event('wallet-standard:app-ready')
        readyEvent.detail = { register: (gui) => window.gui = gui }

        const emitAppReady = () => window.dispatchEvent(readyEvent)
        setTimeout(() => emitAppReady(), 3000)
        """
        contentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

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
        }
    }
}
