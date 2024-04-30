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

    @ObservableUserDefault(.init(key: "gpt-apikey", defaultValue: "", store: .standard))
    @ObservationIgnored
    var gptAPIKey: String

    @ObservableUserDefault(.init(key: "gpt-server", defaultValue: "", store: .standard))
    @ObservationIgnored
    var gptServer: String

    @ObservableUserDefault(.init(key: "gpt-model", defaultValue: "", store: .standard))
    @ObservationIgnored
    var model: String

    @ObservationIgnored
    var modelList: [String] = ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]

    init() {
        if model.isEmpty {
            model = modelList[0]
        }
    }
}
