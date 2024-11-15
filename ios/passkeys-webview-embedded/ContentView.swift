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
                SafariView(url: url, showSafariView: $showSafariView)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Binding var showSafariView: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator // Set the delegate
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var parent: SafariView

        init(_ parent: SafariView) {
            self.parent = parent
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.showSafariView = false // Close SafariView when "Done" is pressed
        }
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
