import SafariServices
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String
    @EnvironmentObject var safariViewManager: SafariViewManager
    @State private var urlToOpen: URL?

    var body: some View {
        let delegate = WebviewDelegate(openURLHandler: { url in
            Task { @MainActor in
                self.urlToOpen = url
                self.safariViewManager.isSafariViewVisible = true
            }
        }, safariViewManager: safariViewManager)

        ZStack {
            Webview(url: URL(string: embeddedWalletUrl)!, uiDelegate: delegate)
                .ignoresSafeArea()
                .navigationTitle("Passkeys")
                .navigationBarTitleDisplayMode(.inline)

            if let url = urlToOpen, safariViewManager.isSafariViewVisible {
                SafariView(url: url, showSafariView: $safariViewManager.isSafariViewVisible, onDismiss: {})
            }
        }
    }
}

final class SafariView: UIViewControllerRepresentable {
    let url: URL
    @Binding var showSafariView: Bool
    var onDismiss: () -> Void

    init(url: URL, showSafariView: Binding<Bool>, onDismiss: @escaping () -> Void) {
        self.url = url
        self._showSafariView = showSafariView
        self.onDismiss = onDismiss
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        weak var parent: SafariView?

        init(_ parent: SafariView) {
            self.parent = parent
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            guard let parent = parent else { return }

            DispatchQueue.main.async {
                parent.showSafariView = false
                parent.onDismiss()
            }
        }
    }
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
