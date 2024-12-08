//
//  String+Error.swift
//  XCStringGPTTranslate
//
//  Created by wp on 2024/2/27.
//

import Foundation

extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
    public var errorDescription: String? {
        self
    }
}

extension String {
    var nilIfEmpty: String? {
        if isEmpty {
            return nil
        }
        return self
    }
}

extension String {
    var firstCharCapitalized: String {
        let firstLetter = prefix(1).capitalized
        let remainingLetters = dropFirst().lowercased()
        return firstLetter + remainingLetters
    }

    var isFirstCharCapitalized: Bool {
        first?.isUppercase ?? false
    }
}
