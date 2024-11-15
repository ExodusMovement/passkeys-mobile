//
//  ContentView.swift
//  Webview Test
//
//  Created by Jan on 02.10.24.
//
import SafariServices
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String
    @State private var showSafariView = false
    @State private var urlToOpen: URL?

    var body: some View {
        let delegate = WebviewDelegate(openURLHandler: { url in
            self.urlToOpen = url
            self.showSafariView = true
        })

        ZStack {
            Webview(url: URL(string: embeddedWalletUrl)!, uiDelegate: delegate)
                .ignoresSafeArea()
                .navigationTitle("Passkeys")
                .navigationBarTitleDisplayMode(.inline)

            if let url = urlToOpen, showSafariView {
                SafariView(url: url)
                    .onDisappear { showSafariView = false }
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}

class WebviewDelegate: NSObject, WKUIDelegate {
    private var openURLHandler: (URL) -> Void

    init(openURLHandler: @escaping (URL) -> Void) {
        self.openURLHandler = openURLHandler
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            openURLHandler(url)
        }
        
        return nil
    }
}
