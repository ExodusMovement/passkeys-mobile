import Combine

@MainActor
class SafariViewManager: ObservableObject {
    @Published var isSafariViewVisible: Bool = false
}