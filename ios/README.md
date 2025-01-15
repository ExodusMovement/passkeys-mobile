# Passkeys

Passkeys

## Installation

```pod
Pod::Spec.new do |s|
  s.name         = "passkeys-react-native"
  ...

  s.dependency 'Passkeys', '~> 1.0.2'
```

## Usage

```swift
import SwiftUI
import Passkeys

@main
struct passkeys_webview_embeddedApp: App {
    var body: some Scene {
        WindowGroup {
            let passkeysView = Passkeys(appId: "test")

            VStack {
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
            }
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
```

## Publishing

We are publishing to cocoapods. Before publishing you will need to adjust [the podspec](./Passkeys.podspec) to contain the correct shasum of the version you are trying to publish.

## License

MIT
