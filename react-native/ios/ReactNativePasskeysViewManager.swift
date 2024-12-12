import SwiftUI

@objc(ReactNativePasskeysViewManager)
class ReactNativePasskeysViewManager: RCTViewManager {
  private var webViewModel: WebViewModel?

  override static func moduleName() -> String {
    return "ReactNativePasskeysViewManager"
  }

  override func view() -> (UIView) {
    webViewModel = WebViewModel()
    let passkeysView = PasskeysMobile(viewModel: webViewModel!)

    let hostingController = UIHostingController(rootView: passkeysView)
    return hostingController.view
  }

  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc
  func callMethod(_ view: NSNumber, _ method: String, data: [String: Any]) {
    print("test callMethod")
    guard let webView = webViewModel!.webView else {
        // rejecter("WEBVIEW_NOT_INITIALIZED", "WebView is not initialized", nil)
        return
    }

    let dataJSON: String
    if let jsonData = try? JSONSerialization.data(withJSONObject: data),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        dataJSON = jsonString
    } else {
        // rejecter("INVALID_JSON", "Failed to serialize data to JSON", nil)
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

    Task {
        do {
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: [:],
                contentWorld: .page
            )
            // resolver(result)
        } catch {
            // rejecter("CALL_METHOD_ERROR", error.localizedDescription, error)
        }
    }
}
}
