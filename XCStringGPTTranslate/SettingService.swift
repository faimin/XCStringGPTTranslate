//
//  SettingService.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import Foundation
import ObservableUserDefault

@Observable
class SettingService {
    static let shared = SettingService()

    @ObservableUserDefault(.init(key: "gpt-key", defaultValue: "", store: .standard))
    @ObservationIgnored
    var gptKey: String

    @ObservableUserDefault(.init(key: "gpt-server", defaultValue: "", store: .standard))
    @ObservationIgnored
    var gptServer: String
}
