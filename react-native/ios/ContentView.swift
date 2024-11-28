import SafariServices
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String
    @State private var urlToOpen: URL?

    var body: some View {
        let delegate = WebviewDelegate(openURLHandler: { url in
            self.urlToOpen = url

            if let ctrl = RCTPresentedViewController() {
                let safariView = SafariView(
                    url: URL(string: embeddedWalletUrl)!,
                    onDismiss: {
                        ctrl.dismiss(animated: true)
                    }
                )
                let hostingController = UIHostingController(rootView: safariView)
                ctrl.present(hostingController, animated: true)
            } else {
                print("Failed to retrieve presented view controller.")
            }
        })

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
    private var openURLHandler: (URL) -> Void

    init(openURLHandler: @escaping (URL) -> Void) {
        self.openURLHandler = openURLHandler
    }

    func closeSafariView() {}

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
