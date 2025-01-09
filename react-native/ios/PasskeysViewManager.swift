import SwiftUI

class HostingAwareView<T: View>: UIView {
    var hostingController: UIHostingController<T>?
}

@objc(PasskeysViewManager)
class PasskeysViewManager: RCTViewManager {
    override func view() -> (UIView) {
        let passkeysView = PasskeysMobileView()
        let hostingController = UIHostingController(rootView: passkeysView)
        let customView: HostingAwareView<PasskeysMobileView> = HostingAwareView()
        customView.hostingController = hostingController
        customView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: customView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: customView.bottomAnchor)
        ])

        return customView
    }

  @objc(callMethod:method:data:resolver:rejecter:)
  func callMethod(_ reactTag: NSNumber, _ method: String, data: [String: Any], resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      guard let view = self.bridge.uiManager.view(forReactTag: reactTag) as? HostingAwareView<PasskeysMobileView> else {
          rejecter("INVALID_VIEW", "Didn't find view from reference", nil)
          return
      }

      let hostingController :UIHostingController<PasskeysMobileView> = view.hostingController!
      let passkeys = hostingController.rootView

      passkeys.callMethod(method, data: data) { result in
        switch result {
          case .success(let value):
              resolver(value)
          case .failure(let error):
              rejecter("EXECUTION_ERROR", error.localizedDescription, nil)
        }
      }
    }
  }
}
