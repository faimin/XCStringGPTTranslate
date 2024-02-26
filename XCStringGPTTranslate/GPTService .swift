//
//  GPTService.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import Foundation

struct ProcessMessage {
    var message: String = ""
    var success = false
}

@Observable
class GPTService {
    @ObservationIgnored
    let fileUrl: URL
    var model: XCStringModel
    var baseLang: String {
        didSet {
            updateLangsList()
        }
    }

    private(set) var processMessage: ProcessMessage?
    private(set) var langs: [String]
    private(set) var isRunning = false

    init(fileUrl: URL) throws {
        let model = try JSONDecoder().decode(XCStringModel.self, from: Data(contentsOf: fileUrl))
        var langs: [String] = []
        model.strings.forEach { _, val in
            let _langs = val.localizations.map(\.key)
            if langs.count < _langs.count {
                langs = _langs
            }
        }

        self.fileUrl = fileUrl
        self.model = model
        self.langs = langs
        baseLang = model.sourceLanguage
        updateLangsList()
    }

    private func updateLangsList() {
        var langs = langs
        for i in 0 ..< langs.count {
            if langs[i] == baseLang {
                langs.remove(at: i)
                langs.insert(baseLang, at: 0)
                break
            }
        }
        self.langs = langs
    }

    func startAll() {
        processMessage = nil
        isRunning = true
    }

    func startKey(_: String) {
        processMessage = nil
        isRunning = true
    }

    func stop() {
        isRunning = false
    }
}
