//
//  passkeys_webview_embeddedApp.swift
//  passkeys-webview-embedded
//
//  Created by Jan on 11.10.24.
//

import SwiftUI
import PasskeysMobile

@main
struct passkeys_webview_embeddedApp: App {
    var body: some Scene {
        WindowGroup {
            PasskeysMobile()
                .environment(\.embeddedWalletUrl, "https://wallet-d.passkeys.foundation/playground?relay")
        }
    }
}
