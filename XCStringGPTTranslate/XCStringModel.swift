//
//  XCStringModel.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import CodableWrapper
import Foundation

struct StringUnit: Codable {
    var state: String
    var value: String

    init(state: String, value: String) {
        self.state = state
        self.value = value
    }
}

struct I18nUnit: Codable {
    var stringUnit: StringUnit

    init(stringUnit: StringUnit) {
        self.stringUnit = stringUnit
    }
}

@Codable
struct LocalizationString: Codable {
    var extractionState: String?
    var localizations: [String: I18nUnit] = [:]
}

struct XCStringModel: Codable {
    let sourceLanguage: String
    let version: String
    var strings: [String: LocalizationString] = [:]
}
