// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common
import Storage

struct TranslationMessage: Codable {
    let type: String // TODO(Issam): this can be an enum
    let payload: Payload

    struct Payload: Codable {
        let fromLanguage: String
        let toLanguage: String
        let innerWindowId: String
    }
}

class TranslationsHelper: TabContentScript {
    // MARK: - Handler Names Enum
    enum HandlerName: String {
        case translations
    }

    // MARK: - Properties

    private weak var tab: Tab?
    private var logger: Logger = DefaultLogger.shared
    private var frame: WKFrameInfo?

    // MARK: - Class Methods

    class func name() -> String {
        return "translations"
    }

    // MARK: - Initialization

    required init(tab: Tab) {
        self.tab = tab
    }

    // MARK: - Script Message Handler

    func scriptMessageHandlerNames() -> [String]? {
        return [HandlerName.translations.rawValue]
    }

    // MARK: - Retrieval

    /// Called when the user content controller receives a script message.
    ///
    /// - Parameters:
    ///   - userContentController: The user content controller.
    ///   - message: The script message received.
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.body)
                let decodedMessage = try JSONDecoder().decode(TranslationMessage.self, from: jsonData)
                let innerWindowId = decodedMessage.payload.innerWindowId
                guard let body = message.body as? [String: Any] else {
                    print("[issam] Invalid script message body: \(message.body)")
                    return
                }
                FrameRegistry.shared.register(message.frameInfo, for: innerWindowId)
                TranslationsBackgroundEngine.shared.forwardMessage(body)
            } catch {
                logger.log("[issam] Failed to decode message: \(error)", level: .fatal, category: .webview)
            }
    }
}
