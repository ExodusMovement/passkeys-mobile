import SafariServices
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String
    @EnvironmentObject var safariViewManager: SafariViewManager
    @State private var urlToOpen: URL?

    var body: some View {
        let delegate = WebviewDelegate(openURLHandler: { url in
            self.urlToOpen = url

            if let ctrl = RCTPresentedViewController() {
                let safariView = SafariView(
                    url: URL(string: embeddedWalletUrl)!,
                    safariViewManager: safariViewManager,
                )
                let hostingController = UIHostingController(rootView: safariView)
                ctrl.present(hostingController, animated: true)
            } else {
                print("Failed to retrieve presented view controller.")
            }
        }, safariViewManager: safariViewManager)

        ZStack {
            Webview(url: URL(string: embeddedWalletUrl)!, uiDelegate: delegate)
                .ignoresSafeArea()
                .navigationTitle("Passkeys")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    private var safariViewManager: SafariViewManager

    init(url: URL, safariViewManager: SafariViewManager, onDismiss: @escaping () -> Void) {
        self.url = url
        self.safariViewManager = safariViewManager
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

class WebviewDelegate: NSObject, WKUIDelegate {
    private var openURLHandler: (URL) -> Void
    private var safariViewManager: SafariViewManager

    init(openURLHandler: @escaping (URL) -> Void, safariViewManager: SafariViewManager) {
        self.openURLHandler = openURLHandler
        self.safariViewManager = safariViewManager
    }

    func closeSafariViewManager() {
        Task { @MainActor in
            safariViewManager.isSafariViewVisible = false
        }
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
