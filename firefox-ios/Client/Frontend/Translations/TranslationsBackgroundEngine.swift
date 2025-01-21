// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import WebKit

/// A registry for managing WKFrameInfo instances using weak references.
/// This is used to keep track of trasnlation requests from all frames.
/// Keep track of frames instead of webviews or tabs since it makes it more generic.
/// ID is generated in JS before sending the initialization message
/// TODO(Issam): Does swift have a better WeakMap implementation ( Maybe NSMapTable ? ) ?
/// We don't want to prevent stuff from being gc.
final class FrameRegistry {
    static let shared = FrameRegistry()
    private(set) var frames = [String: WKFrameInfo]()

    private init() {}

    func register(_ frame: WKFrameInfo?, for windowId: String) {
        guard let frame = frame else { return }
        frames[windowId] = frame
    }

    func unregister(for windowId: String) {
        frames.removeValue(forKey: windowId)
    }

    func frame(for windowId: String) -> WKFrameInfo? {
        return frames[windowId]
    }
}


/// Translations engine should run in the background seperate from running tabs and should only be instantiated once.
/// This is done because loading the models is expensive.
/// TODO(Issam): Run some benchmarks to get some initial values.
class TranslationsBackgroundEngine: NSObject, WKScriptMessageHandlerWithReply {
    static let shared = TranslationsBackgroundEngine()

    private var backgroundWebView: WKWebView?

    override private init() {
        super.init()
        setupBackgroundWebView()
    }

    private func setupBackgroundWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "translationsBackground")
        config.userContentController = contentController

        backgroundWebView = WKWebView(frame: .zero, configuration: config)
        backgroundWebView?.isHidden = true

        #if targetEnvironment(simulator)
        // Allow Safari Web Inspector only when running in simulator.
        // Requires to toggle `show features for web developers` in
        // Safari > Settings > Advanced menu.
        if #available(iOS 16.4, *) {
            backgroundWebView?.isInspectable = true
        }
        // Webview needs to be in the view tree to show up in the inspector
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first, let backgroundWebView = backgroundWebView {
            window.addSubview(backgroundWebView)
        }
        #endif
        /// Only for debugging
        TranslationsModelsManager.shared.purgeAllData()
        TranslationsModelsManager.shared.loadTranslationsManifest()
        loadLocalFile("TranslationsBackground", relativeTo: Bundle.main.bundleURL)
    }

    private func loadLocalFile(_ filePath: String, relativeTo baseURL: URL) {
        if let url = Bundle.main.url(forResource: filePath, withExtension: "html") {
            let request = URLRequest(url: url)
            backgroundWebView?.loadFileURL(url, allowingReadAccessTo: url)
            backgroundWebView?.load(request)
        }
    }

    func forwardMessage(_ message: [String: Any]) {
        /// NOTE(Issam): Make this an enum and decode.
        guard let type = message["type"] as? String,
              let payload = message["payload"] as? [String: Any],
              let _ = payload["innerWindowId"] as? String else {
            print("[issam] Invalid message structure: \(message)")
            return
        }
        guard let script = convertMessageToJavaScript(payload) else { return }
        let functionCall = type == "port" ? "portPostMessage(\(script))" : "backgroundPostMessage(\(script))"
        backgroundWebView?.evaluateJavaScript(functionCall, completionHandler: nil)
    }

    /// Converts the message into a JavaScript function call
    private func convertMessageToJavaScript(_ message: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }

    // TODO(Issam): Clean this up with an enum of expected types and split into functions ( router ).
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              let payload = body["payload"] as? [String: Any] else {
            print("[issam] Invalid message structure: \(message.body)")
            replyHandler("error", nil)
            return
        }

        _ = (type, payload)

        if type == "getModels" {
            // TODO(Issam): Change this to "from:to:" args.
            TranslationsModelsManager.shared.fetchModelsInJSFormat(for: "en", toLang: "fr") { result in
                switch result {
                    case .success(let response):
                        let fullResponse: [String: Any] = [
                            "languageModelFiles": response,
                            "sourceLanguage": "en",
                            "targetLanguage": "fr"
                        ]
                        replyHandler(fullResponse, nil)
                    case .failure(let error):
                        replyHandler(["error": error.localizedDescription], nil)
                    }
            }
        } else if type == "forward" {
            // TODO(Issam): tmp until we figure out the id -> frame mapping just get the first one.
            // This is nasty.
            let frame = FrameRegistry.shared.frames.first?.value
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("Failed to serialize payload to JSON")
                return
            }
            let jsCommand = "forwardMessageToContent(\(jsonString))"

            frame?.webView?.evaluateJavaScript(jsCommand, in: nil, in: .defaultClient) { result in
                switch result {
                case .success(let returnValue):
                    print("JavaScript executed successfully, result: \(String(describing: returnValue))")
                    replyHandler("done", nil)
                case .failure(let error):
                    print("JavaScript execution failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
