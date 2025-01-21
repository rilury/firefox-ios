// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// QUESTION(Issam): Does swift has a built-in trait for this ? Otherwise we can serialize before
/// sending to JS
protocol DictionaryConvertible {
    func toDictionary() -> [String: Any]
}

enum TranslationsModelFileType: String, Codable {
    case lex, vocab, model
}


struct Attachment: Codable, Equatable {
    let hash: String
    let size: Int
    let filename: String
    let location: String
    let mimetype: String
    
    func toDictionary() -> [String: Any] {
        return [
            "hash": hash,
            "size": size,
            "filename": filename,
            "location": location,
            "mimetype": mimetype
        ]
    }
}

struct TranslationsModelRecord: RemoteDataTypeRecord {
    let id: String
    let lastModified: Int
    let name: String
    let fromLang: String
    let toLang: String
    let version: String
    let fileType: TranslationsModelFileType
    let attachment: Attachment

    enum CodingKeys: String, CodingKey {
        case id
        case lastModified = "last_modified"
        case name
        case fromLang
        case toLang
        case version
        case fileType
        case attachment
    }

    public static func == (lhs: TranslationsModelRecord, rhs: TranslationsModelRecord) -> Bool {
        return lhs.id == rhs.id &&
        lhs.lastModified == rhs.lastModified
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "lastModified": lastModified,
            "name": name,
            "fromLang": fromLang,
            "toLang": toLang,
            "version": version,
            "fileType": fileType.rawValue,
            "attachment": attachment.toDictionary()
        ]
    }
}
