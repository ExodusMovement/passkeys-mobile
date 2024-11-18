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
    @EnvironmentObject var safariViewManager: SafariViewManager
    @State private var urlToOpen: URL?
    @State private var refreshID = UUID()

    var body: some View {
        let delegate = WebviewDelegate(openURLHandler: { url in
            self.urlToOpen = url
            self.safariViewManager.isSafariViewVisible = true
        })

        ZStack {
            // Update Webview to depend on refreshID to reload when it changes
            CustomWebview(url: URL(string: embeddedWalletUrl)!, uiDelegate: delegate)
                .id(refreshID)
                .ignoresSafeArea()
                .navigationTitle("Passkeys")
                .navigationBarTitleDisplayMode(.inline)

            if let url = urlToOpen, safariViewManager.isSafariViewVisible {
                SafariView(url: url, showSafariView: $safariViewManager.isSafariViewVisible, onDismiss: {
                    self.refreshID = UUID()
                })
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Binding var showSafariView: Bool
    var onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var parent: SafariView

        init(_ parent: SafariView) {
            self.parent = parent
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.showSafariView = false
            parent.onDismiss()
        }
    }
}

struct CustomWebview: UIViewRepresentable {
    let url: URL
    let uiDelegate: WebviewDelegate

    func makeUIView(context: Context) -> WKWebView {
        // Create a custom configuration with persistent storage
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = uiDelegate
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Optional: Handle updates to the view if needed
    }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.openURLHandler(url)
            }
        }
        return nil
    }
}
