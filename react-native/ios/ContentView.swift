import SafariServices
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String

    var body: some View {
        var delegate: WebviewDelegate!
        delegate = WebviewDelegate(openURLHandler: { url in
            if let ctrl = RCTPresentedViewController() {
                delegate.presentSafariView(from: ctrl, url: url)
            } else {
                print("Failed to retrieve presented view controller.")
            }
        })

        return ZStack {
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
    private weak var hostingController: UIViewController?

    init(openURLHandler: @escaping (URL) -> Void) {
        self.openURLHandler = openURLHandler
    }

    func presentSafariView(from ctrl: UIViewController, url: URL) {
        let safariView = SafariView(
            url: url,
            onDismiss: {
                ctrl.dismiss(animated: true)
                self.hostingController = nil
            }
        )
        let hostingController = UIHostingController(rootView: safariView)
        self.hostingController = hostingController
        ctrl.present(hostingController, animated: true)
    }

    func closeSafariView() {
        hostingController?.dismiss(animated: true, completion: {
            self.hostingController = nil
        })
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