//
//  passkeys_webview_embeddedApp.swift
//  passkeys-example
//
//  Created by Jan on 11.10.24.
//

import SwiftUI
import Passkeys

@main
struct passkeys_webview_embeddedApp: App {
    @StateObject private var viewModel = WebViewModel()

    var body: some Scene {
        WindowGroup {
            let passkeysView = Passkeys(appId: "test", viewModel: viewModel)

            VStack(spacing: 16) {
                Button("Connect") {
                    passkeysView.callMethod("connect", data: nil) { result in
                        switch result {
                        case .success(let response):
                            print("Success: \(response ?? "nil")")
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
                .disabled(viewModel.isLoading || viewModel.loadingErrorMessage != nil)

                if let errorMessage = viewModel.loadingErrorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
            .background(
                ZStack {
                    passkeysView
                        .frame(width: 1, height: 1)
                        .opacity(0)
                }
            )
        }
    }
}
