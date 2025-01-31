import SwiftUI
import Passkeys

// todo remove in next iOS bump, made it public in the iOS lib
enum CustomError: Error, LocalizedError {
    case message(String)

    public var errorDescription: String? {
        switch self {
        case .message(let msg):
            return msg
        }
    }
}

class HostingAwareView<T: View>: UIView {
    var hostingController: UIHostingController<T>?
}

@objc(PasskeysView)
class PasskeysView: UIView {
  let viewModel = WebViewModel()

  @objc var appId: String? = nil {
    didSet {
      viewModel.appId = appId
      updateHostingController()
    }
  }
  @objc var url: String? = nil {
    didSet {
      viewModel.url = url
      updateHostingController()
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
    let passkeysView = Passkeys(appId: appId, url: url, viewModel: viewModel)
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

  private func updateHostingController() {
    guard let hostingController = hostingController else { return }
    hostingController.rootView = Passkeys(appId: appId, url: url, viewModel: viewModel)
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
