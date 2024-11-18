//
//  passkeys_webview_embeddedApp.swift
//  passkeys-webview-embedded
//
//  Created by Jan on 11.10.24.
//

import SwiftUI

@main
struct passkeys_webview_embeddedApp: App {
    @StateObject private var safariViewManager = SafariViewManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(safariViewManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        if url.scheme == "passkeys" {
            // Handle the URL
            print("Handling passkeys URL: \(url)")
            safariViewManager.isSafariViewVisible = false // Dismiss SafariView
        }
    }
}
