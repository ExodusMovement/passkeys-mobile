import SwiftUI

class HostingAwareView<T: View>: UIView {
    var hostingController: UIHostingController<T>?
}

@objc(PasskeysView)
class PasskeysView: UIView {
  @objc var appId: String = ""
  @objc var url: String? = nil

  private(set) var hostingController: UIHostingController<PasskeysMobileView>?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupHostingController()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupHostingController()
  }

  private func setupHostingController() {
    let passkeysView = PasskeysMobileView(appId: appId, url: nil)
    hostingController = UIHostingController(rootView: passkeysView)

    if let hostedView = hostingController?.view {
      addSubview(hostedView)
      hostedView.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate([
        hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
        hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
        hostedView.topAnchor.constraint(equalTo: topAnchor),
        hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
      ])
    }
  }
}

@objc(PasskeysViewManager)
class PasskeysViewManager: RCTViewManager {
  @objc override static func moduleName() -> String! {
    return "PasskeysView"
  }

  override func view() -> UIView! {
    return PasskeysView()
  }

  @objc(callMethod:method:data:resolver:rejecter:)
  func callMethod(
    _ reactTag: NSNumber,
    _ method: String,
    data: [String: Any],
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      guard
        let passkeysView = self.bridge.uiManager.view(forReactTag: reactTag) as? PasskeysView,
        let hostingController = passkeysView.hostingController
      else {
        rejecter("INVALID_VIEW", "Did not find PasskeysView for the given tag.", nil)
        return
      }

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
