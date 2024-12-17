import SwiftUI
import WebKit

struct Webview: UIViewRepresentable {
    let url: URL
    var navigationDelegate: WKNavigationDelegate?
    var uiDelegate: WKUIDelegate?

    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.isInspectable = true
        webview.navigationDelegate = navigationDelegate
        webview.uiDelegate = uiDelegate
        
        return webview
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
