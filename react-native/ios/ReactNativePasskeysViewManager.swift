import SwiftUI

class HostingAwareView<T: View>: UIView {
    weak var hostingController: UIHostingController<T>?
}

@objc(ReactNativePasskeysViewManager)
class ReactNativePasskeysViewManager: RCTViewManager {
  // passkeysView: PasskeysMobile?
  private var webViewModel: WebViewModel?

  override func view() -> (UIView) {
    webViewModel = WebViewModel()
    let passkeysView = PasskeysMobile(viewModel: webViewModel!)

    let hostingController = UIHostingController(rootView: passkeysView)
    let customView: HostingAwareView<PasskeysMobile> = HostingAwareView()
    customView.hostingController = hostingController
    hostingController.view = customView
    return customView as UIView
  }

  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc(callMethod:method:data:resolver:rejecter:)
  func callMethod(_ reactTag: NSNumber, _ method: String, data: [String: Any], resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    print("test here 1")
    DispatchQueue.main.async {
      guard let view = self.bridge.uiManager.view(forReactTag: reactTag)! as? HostingAwareView<PasskeysMobile> else {
          // Notify JavaScript about the error
          rejecter("INVALID_VIEW", "Didn't find view from reference", nil)
          return
      }
      print("test here 3", self.webViewModel)
      if let hostingController = view.hostingController {
          let passkeysMobileView = hostingController.rootView
          print("Found PasskeysMobile instance: \(passkeysMobileView)")
      }
      else {
        print("not Found PasskeysMobile instance")
      }
      
//      let hostingController :UIHostingController<PasskeysMobile> = view.hostingController!
      // guard let hostingController = view.getHostingController() as? UIHostingController<PasskeysMobile> else {
      //     // Notify JavaScript about the error
      //     rejecter("INVALID_VIEW", "Didn't find passkeys view from reference", nil)
      //     return
      // }
//      print("test here 4", hostingController)
//      let passkeys = hostingController.rootView
      let dataJSON: String
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
          let jsonString = String(data: jsonData, encoding: .utf8) {
            dataJSON = jsonString
        } else {
            rejecter("INVALID_JSON", "Failed to serialize data to JSON", nil)
            return
        }

        // Task {
        //     do {
        //         let result = try await webView.callAsyncJavaScript(
        //             script,
        //             arguments: [:],
        //             contentWorld: .page
        //         )
        //         resolver(result)
        //     } catch {
        //         rejecter("CALL_METHOD_ERROR", error.localizedDescription, error)
        //     }
        // }

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
        // passkeys.callMethod(method, data: data) { result in
        //   switch result {
        //     case .success(let value):
        //         resolver(value)
        //     case .failure(let error):
        //         rejecter("EXECUTION_ERROR", error.localizedDescription, nil)
        //   }
        // }

        
    }
  }
}
