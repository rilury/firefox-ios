// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common

class SummarizerHelper {
      static func fetchPageContent(
        from webView: WKWebView,
        completion: @escaping (String?, Error?) -> Void
      ) {
          
          let js = "window.__firefox__.summarizer.readerize();"
          
          webView.evaluateJavaScript(js, in: nil, in: .defaultClient) { result in
              switch result {
              case .failure(let error):
                  completion(nil, error)
                  
              case .success(let anyValue):
                  if let string = anyValue as? String {
                      completion(string, nil)
                  }
                  else {
                      completion(nil, nil)
                  }
              }
          }
      }

}
