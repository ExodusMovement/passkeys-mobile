//
//  passkeys_webview_embeddedApp.swift
//  passkeys-webview-embedded
//
//  Created by Jan on 11.10.24.
//

import SwiftUI

@main
struct passkeys_webview_embeddedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
