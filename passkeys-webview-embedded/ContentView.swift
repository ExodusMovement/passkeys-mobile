import AuthenticationServices
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String
    @State private var showAuthSession = false
    @State private var urlToOpen: URL?
    private let authSessionCoordinator = AuthSessionCoordinator()

    var body: some View {
        let delegate = WebviewDelegate(openURLHandler: { url in
            self.urlToOpen = url
            self.showAuthSession = true
            authSessionCoordinator.startAuthSession(url: url)
        })

        ZStack {
            Webview(url: URL(string: embeddedWalletUrl)!, uiDelegate: delegate)
                .ignoresSafeArea()
                .navigationTitle("Passkeys")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

class AuthSessionCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var authSession: ASWebAuthenticationSession?

    func startAuthSession(url: URL) {
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { callbackURL, error in
            if let error = error {
                print("Authentication failed with error: \(error.localizedDescription)")
            } else if let callbackURL = callbackURL {
                print("Authentication succeeded with callback URL: \(callbackURL)")
            }
        }
        authSession?.presentationContextProvider = self
        authSession?.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
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
            openURLHandler(url)
        }
        
        return nil
    }
}
