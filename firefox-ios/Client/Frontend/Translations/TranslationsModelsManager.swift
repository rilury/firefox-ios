// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// NOTE(Issam): Probably remove this when we have phase 2 of RS.
class TranslationsModelsManager {
    static let shared = TranslationsModelsManager()
    static let translationsModelsDir = "TranslationModels"
    static let attachmentsBaseURL = URL("https://firefox-settings-attachments.cdn.mozilla.net/")!
    /// NOTE(Issam): On Desktop, version is pinned in code too.
    static let version = "1.0"
    private var cachedTranslationsManifest: [TranslationsModelRecord]?
    private let storageKey = "StoredTranslationModels"

    /// Store the binary models in app support
    lazy var appSupportURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent(TranslationsModelsManager.translationsModelsDir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func loadTranslationsManifest() {
        guard cachedTranslationsManifest == nil else { return }
        Task {
            let remoteSettingsUtils = RemoteSettingsUtils()
            cachedTranslationsManifest = await remoteSettingsUtils.fetchLocalRecords(for: .translationsModels)
        }
    }

    /// Attempt to download and save models. If model already exist, return from cache instead of re-downloading.
    func fetchModels(for fromLang: String, toLang: String, version: String = TranslationsModelsManager.version,
                     completion: @escaping (Result<[String: String], Error>) -> Void) {
        if let storedModels = getStoredModels(fromLang: fromLang, toLang: toLang, version: version) {
            completion(.success(storedModels))
            return
        }

        guard let manifest = cachedTranslationsManifest else {
            completion(.failure(NSError(domain: "Manifest", code: 404, userInfo: nil)))
            return
        }

        let requiredModels = manifest.filter { $0.fromLang == fromLang && $0.toLang == toLang && $0.version == version }
        guard requiredModels.count == 3 else {
            completion(.failure(NSError(domain: "Manifest", code: 404, userInfo: nil)))
            return
        }
        downloadModels(requiredModels, completion: completion)
    }

    /// Check if models exist in UserDefaults before downloading
    private func getStoredModels(fromLang: String, toLang: String, version: String) -> [String: String]? {
        guard let storedData = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [String: String]] else {
            return nil
        }
        return storedData["\(fromLang)-\(toLang)-\(version)"]
    }

    /// Save model file paths in UserDefaults
    private func saveStoredModels(fromLang: String, toLang: String, version: String, models: [String: String]) {
        var storedData = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [String: String]] ?? [:]
        storedData["\(fromLang)-\(toLang)-\(version)"] = models
        UserDefaults.standard.set(storedData, forKey: storageKey)
    }

    /// TODO(Issam): Cleanup later and use async/await. This is a bit too messy.
    func downloadModels(_ entries: [TranslationsModelRecord],
                        completion: @escaping (Result<[String: String], Error>) -> Void) {
        var downloadedModels: [String: String] = [:]
        let group = DispatchGroup()

        for entry in entries {
            group.enter()
            let fileURL = TranslationsModelsManager.attachmentsBaseURL.appendingPathComponent(entry.attachment.location)
            let saveURL = appSupportURL.appendingPathComponent(entry.attachment.filename)

            URLSession.shared.downloadTask(with: fileURL) { tempURL, _, error in
                guard let tempURL = tempURL, error == nil else { group.leave(); return }
                try? FileManager.default.removeItem(at: saveURL)
                do {
                    try FileManager.default.moveItem(at: tempURL, to: saveURL)
                    downloadedModels[entry.fileType.rawValue] = saveURL.path
                } catch {
                    completion(.failure(error))
                }
                group.leave()
            }.resume()
        }

        group.notify(queue: .main) {
            self.saveStoredModels(fromLang: entries[0].fromLang,
                                  toLang: entries[0].toLang,
                                  version: entries[0].version,
                                  models: downloadedModels)
            completion(.success(downloadedModels))
        }
    }

    /// NOTE(Issam): For debugging only to see if caching/download works.
    func purgeAllData() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        let directory = appSupportURL
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// TODO(Issam): Cleanup. This is a wrapper to make the data in the format JS expects, but this makes the code really complicated.
    func fetchModelsInJSFormat(for fromLang: String, toLang: String, version: String = TranslationsModelsManager.version,
                               completion: @escaping (Result<[String: [String: Any]], Error>) -> Void) {
        
        fetchModels(for: fromLang, toLang: toLang, version: version) { result in
            switch result {
            case .success(let models):
                var response: [String: [String: Any]] = [:]

                for (fileType, path) in models {
                    if let modelData = self.prepareJSResponse(fileType: fileType, path: path,
                                                              fromLang: fromLang, toLang: toLang, version: version) {
                        response[fileType] = modelData
                    }
                }

                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// The JS code expects data in a certain format. We can do the processing in JS too. But this seems to be better.
    /// TODO(Issam): Cleanup. This is a bit unreadable.
    private func prepareJSResponse(fileType: String, path: String, fromLang: String,
                                   toLang: String, version: String) -> [String: Any]? {
        let fileURL = URL(fileURLWithPath: path)
        guard let fileData = try? Data(contentsOf: fileURL) else { return nil }

        // Break down filter conditions separately
        let isMatchingModel: (TranslationsModelRecord) -> Bool = { model in
            model.fileType.rawValue == fileType &&
            model.fromLang == fromLang &&
            model.toLang == toLang &&
            model.version == version
        }

        guard let manifest = cachedTranslationsManifest,
              let record = manifest.first(where: isMatchingModel) else {
            return nil
        }

        return [
            "buffer": fileData.base64EncodedString(),
            "record": record.toDictionary()
        ]
    }
}
