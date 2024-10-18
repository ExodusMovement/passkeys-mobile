//
//  ContentView.swift
//  Webview Test
//
//  Created by Jan on 02.10.24.
//
import WebKit
import SwiftUI

struct ContentView: View {
    @Environment(\.embeddedWalletUrl) var embeddedWalletUrl: String

       
   var body: some View {
       let delegate = WebviewDelegate()
       
       Webview(url: URL(string: embeddedWalletUrl)!, uiDelegate: delegate)
           .ignoresSafeArea()
           .navigationTitle("Passkeys")
           .navigationBarTitleDisplayMode(.inline)
   }
}

class WebviewDelegate: NSObject, WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // this is called on window.open
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        
        return nil
    }
}

#Preview {
    ContentView()
}
