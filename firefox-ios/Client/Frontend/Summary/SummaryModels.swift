// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


// MARK: - Summary Models
struct SummaryRequest: Codable {
    let text: String
    let summaryType: String
    let customLines: Int
    let language: String
}

struct SummaryResponse: Codable {
    let summary: String
    let id: String
    let tokens: Tokens
    
    struct Tokens: Codable {
        let input: Int
        let output: Int
    }
}
