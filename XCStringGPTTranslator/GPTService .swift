//
//  GPTService.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import EventSource
import Foundation
import PathKit
import SwiftUI
import XcodeProj

struct ProcessMessage {
    var message: LocalizedStringKey
    var success: Bool
}

struct GPTServiceTarget: Codable, Hashable, Identifiable {
    var id: URL {
        xcstringURL
    }

    let xcstringURL: URL
    let xcprojURL: URL
}

@Observable
class GPTService {
    @ObservationIgnored
    let target: GPTServiceTarget

    var model: StringCatalog {
        didSet {
            wirteJSONBack()
        }
    }

    var baseLang: String {
        didSet {
            updateLangsList()
        }
    }

    var base2Lang: String {
        didSet {
            updateLangsList()
        }
    }

    private(set) var processMessages: [ProcessMessage] = []
    private(set) var processMessage: ProcessMessage? {
        didSet {
            if let processMessage {
                processMessages.append(processMessage)
            }
        }
    }

    private(set) var langs: [String]
    private(set) var isRunning = false

    @ObservationIgnored
    private var writeDebouncer: Timer?

    @ObservationIgnored
    private var dataTask: URLSessionDataTask?

    init(target: GPTServiceTarget) throws {
        self.target = target
        model = .init(sourceLanguage: "en", strings: [:], version: "1.0")
        baseLang = ""
        base2Lang = ""
        langs = []
        try reload()
    }

    func reload() throws {
        let model = try JSONDecoder().decode(
            StringCatalog.self,
            from: Data(
                contentsOf:
                    target.xcstringURL))
        var langs: [String] = []
        model.strings.forEach { _, val in
            let _langs = val.localizations.map(\.key)
            if langs.count < _langs.count {
                langs = _langs
            }
        }

        let xcodeproj = try XcodeProj(path: Path(target.xcprojURL.path()))
        langs = Set(langs).union(xcodeproj.pbxproj.rootObject?.knownRegions ?? []).sorted()
        langs.removeAll(where: { $0 == "Base" })

        self.model = model
        self.langs = langs.sorted()
        baseLang = baseLang.isEmpty ? model.sourceLanguage : baseLang
        updateLangsList()
        processMessages = []
        processMessage = nil
    }

    func wirteJSONBack() {
        writeDebouncer?.invalidate()
        writeDebouncer = Timer.scheduledTimer(
            withTimeInterval: 0.5, repeats: false,
            block: { [weak self] _ in
                guard let self else { return }
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
                    let data = try encoder.encode(model)
                    try data.write(to: target.xcstringURL)
                } catch {
                    print(error)
                }
            })
    }

    private func updateLangsList() {
        var langs = langs
        for i in 0..<langs.count {
            if langs[i] == base2Lang {
                langs.remove(at: i)
                langs.insert(base2Lang, at: 0)
                break
            }
        }
        for i in 0..<langs.count {
            if langs[i] == baseLang {
                langs.remove(at: i)
                langs.insert(baseLang, at: 0)
                break
            }
        }
        self.langs = langs
    }

    func startKeys(_ keys: [String]) {
        guard !isRunning else { return }
        processMessage = nil
        isRunning = true

        Task { @MainActor in
            var successCount = 0
            var failureCount = 0

            for key in keys {
                processMessage = .init(message: "🟡\(key): Start", success: true)
                do {
                    try await self.request(key)
                    successCount += 1
                } catch {
                    processMessage = .init(message: "🔴\(key): \(error.localizedDescription), Please try again", success: false)
                    failureCount += 1
                }
            }
            if (failureCount + successCount) > 1 {
                processMessage = .init(
                    message: "\(failureCount == 0 ? "🟢" : "🔴")Succeessed: \(successCount)  Failure: \(failureCount)",
                    success: failureCount == 0)
            }
            isRunning = false
        }
    }

    func removeKey(_ key: String) {
        model.strings.removeValue(forKey: key)
    }

    func removeAllTranslated(_ key: String) {
        model.strings[key]?.localizations.map(\.key).forEach { lang in
            if lang != baseLang, lang != base2Lang {
                model.strings[key]?.localizations[lang] = .init(stringUnit: .init(state: "needs_review", value: ""))
            }
        }
    }

    func stop() {
        dataTask?.cancel()
        dataTask = nil
        isRunning = false
    }
}

extension GPTService {
    private func getLangText(_ lang: String, key: String) -> String? {
        guard let locStr = model.strings[key] else {
            return nil
        }
        let str: String?
        if lang == "Comment" {
            str = locStr.comment
        } else if let text = locStr.localizations[lang],
            text.stringUnit?.value.nilIfEmpty != nil
        {
            str = text.stringUnit!.value
        } else if lang == model.sourceLanguage {
            str = key
        } else {
            str = nil
        }
        return str
    }

    fileprivate func generateRequestBody(_ key: String) throws -> [String: Any] {
        guard let locStr = model.strings[key] else {
            throw "unexpected error key: \"\(key)\""
        }

        let baseText: String? = getLangText(baseLang, key: key)
        let base2Text: String? = getLangText(base2Lang, key: key)
        if baseText?.nilIfEmpty == nil, base2Text?.nilIfEmpty == nil {
            throw "empty string in \"\(baseLang)\" for Key: \"\(key)\""
        }

        var toLangs: [String] = []
        langs.forEach { lang in
            if locStr.localizations[lang]?.stringUnit?.value.nilIfEmpty == nil {
                toLangs.append(lang)
            }
        }
        if toLangs.isEmpty {
            throw "no language needs to be translated!"
        }
        var toLangsSchema: [String: Any] = [:]
        toLangs.forEach { lang in
            toLangsSchema[lang] = ["type": "string", "description": "translate to '\(lang)'."]
        }

        let prompt = """
            Translate app content into multiple languages. Maintain the original meaning while considering context and ensuring clarity and fluency in the target languages.

            # Steps
            1. Understand the context of the content to be translated, including any specific jargon or technical terms.
            2. Translate the text ensuring the meaning is preserved.
            3. Review the translation for grammatical correctness and natural flow in each target language.
            4. Verify that any culturally sensitive material is appropriately addressed.

            # Output Format

            Provide the translated versions as plain text output.

            # Examples

            - **Input:**"Hello, welcome to our app!"
              - **Output (Chinese):** 你好，欢迎使用我们的应用程序！
              - **Output (French):** Bonjour, bienvenue dans notre application!

            - **Input:**"Settings"
              - **Output (Spanish):** Configuración 
              - **Output (German):** Einstellungen 

            # Notes

            - Pay attention to context-specific terminology.
            - If unsure, prioritize clarity and readability over a literal translation.
            - Maintain consistency in repeated terms or phrases.
            """

        var userContent = ""
        if let baseText = baseText?.nilIfEmpty {
            userContent.append("**\(baseLang):**\(baseText)\n")
        }
        if let base2Text = base2Text?.nilIfEmpty {
            userContent.append("**\(base2Lang):**\(base2Text)\n")
        }

        var messages: [[String: Any]] = []
        messages.append(["role": "system", "content": prompt])
        messages.append(["role": "user", "content": userContent])

        var body: [String: Any] = [:]
        body["messages"] = messages
        body["response_format"] = [
            "type": "json_schema",
            "json_schema": [
                "name": "multilingual_language",
                "strict": true,
                "schema": ["type": "object", "properties": toLangsSchema, "required": toLangs, "additionalProperties": false],
            ],
        ]

        return body
    }

    fileprivate func handleGPTResponse(data: Data, for key: String) throws {
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let root,
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String,
            var dict = try? JSONSerialization.jsonObject(with: Data.init(content.utf8)) as? [String: String]
        else {
            throw "ParseError: \(String.init(data: data, encoding: .utf8) ?? "") "
        }

        if dict[baseLang]?.nilIfEmpty == nil, baseLang == model.sourceLanguage {
            dict[baseLang] = key
        }
        var translated: [String] = []
        dict.sorted(by: { $0.key < $1.key })
            .filter { langs.contains($0.key) }
            .forEach { lang, value in
                var locStr = model.strings[key] ?? .init(extractionState: "manual")
                if locStr.localizations[lang]?.stringUnit?.value.nilIfEmpty == nil {
                    var fixedValue = value.unescape()
                    if key.isFirstCharCapitalized {
                        fixedValue = fixedValue.firstCharCapitalized
                    }
//                    let rawCapitalizedComps = key.components(separatedBy: " ").filter { $0.isFirstCharCapitalized }
//                    rawCapitalizedComps.forEach { string in
//                        fixedValue = fixedValue.replacingOccurrences(of: string.lowercased(), with: string)
//                    }
                    locStr.localizations[lang] = .init(stringUnit: .init(state: "translated", value: fixedValue))
                    translated.append(lang)
                }
                model.strings[key] = locStr
            }
        processMessage = .init(message: "\(key)  <<< \(translated.joined(separator: ", "))", success: true)
    }

    @MainActor
    fileprivate func request(_ key: String) async throws {
        let setting = SettingService.shared
        if setting.gptAPIKey.isEmpty {
            throw "empty GPT API Key, config it in Settings."
        }

        var body = try generateRequestBody(key)
        body["model"] = setting.model
        body["temperature"] = 1
        body["max_tokens"] = 16383
        body["top_p"] = 1

        var server = setting.gptServer.nilIfEmpty ?? "https://api.openai.com"
        if !server.hasPrefix("http") {
            server = "https://\(server)"
        }
        if server.hasSuffix("/") {
            server.removeLast()
        }
        let urlStr = server + "/v1/chat/completions"
        guard let url = URL(string: urlStr) else {
            throw "error url: \(urlStr)"
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Bearer \(setting.gptAPIKey)",
            "Content-Type": "application/json",
        ]

        print(urlRequest.cURL())

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        try handleGPTResponse(data: data, for: key)
    }
}
