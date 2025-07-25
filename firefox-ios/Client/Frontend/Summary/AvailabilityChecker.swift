// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This is a temporary setting to enable the SummarizationChecker for the initial test build.
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
func getSummarizationCheckerStatus() -> Bool {
    let model = SystemLanguageModel.default
    return model.availability == .available
}
#else
func getSummarizationCheckerStatus() -> Bool {
    return false
}
#endif
