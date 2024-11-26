import SwiftUI

public struct PasskeysMobile: View {
    @StateObject private var safariViewManager = SafariViewManager()

    public init() {}

    public var body: some View {
        ContentView()
            .environmentObject(safariViewManager)
    }
}