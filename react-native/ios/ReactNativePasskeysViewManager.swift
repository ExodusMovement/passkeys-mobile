import SwiftUI

class HostingAwareView<T: View>: UIView {
    var hostingController: UIHostingController<T>?
}

@objc(ReactNativePasskeysViewManager)
class ReactNativePasskeysViewManager: RCTViewManager {
    private var webViewModel: WebViewModel?

    override func view() -> (UIView) {
        webViewModel = WebViewModel()
        let passkeysView = PasskeysMobile(viewModel: webViewModel!)
        let hostingController = UIHostingController(rootView: passkeysView)
        let customView: HostingAwareView<PasskeysMobile> = HostingAwareView()
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
      guard let view = self.bridge.uiManager.view(forReactTag: reactTag) as? HostingAwareView<PasskeysMobile> else {
          rejecter("INVALID_VIEW", "Didn't find view from reference", nil)
          return
      }

      let hostingController :UIHostingController<PasskeysMobile> = view.hostingController!
      let passkeys = hostingController.rootView
      let dataJSON: String
      if let jsonData = try? JSONSerialization.data(withJSONObject: data),
        let jsonString = String(data: jsonData, encoding: .utf8) {
          dataJSON = jsonString
      } else {
          rejecter("INVALID_JSON", "Failed to serialize data to JSON", nil)
          return
      }

      let script = """
      const result = window.\(method)(\(dataJSON));
      if (result instanceof Promise) {
          return result
              .then(resolved => resolved)
              .catch(error => { throw error; });
      } else {
          return result;
      }
      """
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
