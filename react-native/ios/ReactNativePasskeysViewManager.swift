import SwiftUI

@objc(ReactNativePasskeysViewManager)
class ReactNativePasskeysViewManager: RCTViewManager {

  override func view() -> (UIView) {
    let webViewModel = WebViewModel()
    let passkeysView = PasskeysMobile(viewModel: webViewModel)

    let hostingController = UIHostingController(rootView: passkeysView)
    return hostingController.view
  }

  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
