import SwiftUI
import Passkeys

class HostingAwareView<T: View>: UIView {
    var hostingController: UIHostingController<T>?
}

@objc(PasskeysView)
class PasskeysView: UIView {
  @objc var appId: String? = nil {
    didSet {
      hostingController?.rootView.viewModel.appId = appId
    }
  }
  @objc var url: String? = nil {
    didSet {
      hostingController?.rootView.viewModel.url = url
    }
  }

  private(set) var hostingController: UIHostingController<Passkeys>?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupHostingController()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupHostingController()
  }

  private func setupHostingController() {
    let passkeysView = Passkeys(appId: appId, url: url)
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
        rejecter("INVALID_VIEW", "Passkeys instance not initialized", nil)
        return
      }

      let passkeys = hostingController.rootView

      passkeys.callMethod(method, data: data) { result in
        switch result {
          case .success(let value):
            resolver(value)
          case .failure(let error):
            if let customError = error as? CustomError {
              switch customError {
                case .message(let msg):
                  rejecter("EXECUTION_ERROR", msg, nil)
              }
            } else {
              rejecter("EXECUTION_ERROR", "\(error)", nil)
            }
        }
      }
    }
  }
}
