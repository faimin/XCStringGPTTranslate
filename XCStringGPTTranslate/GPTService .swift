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

struct GPTServiceTarget: Codable {
    let xcstringURL: URL
    let xcprojURL: URL
}

@Observable
class GPTService {
    @ObservationIgnored
    let target: GPTServiceTarget

    var model: XCStringModel {
        didSet {
            wirteJSONBack()
        }
    }

    var baseLang: String {
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
    private var eventSource: EventSource?
    @ObservationIgnored
    private var writeDebouncer: Timer?

    init(target: GPTServiceTarget) throws {
        self.target = target
        model = .init(sourceLanguage: "en", version: "1.0")
        baseLang = ""
        langs = []
        try reload()
    }

    func reload() throws {
        let model = try JSONDecoder().decode(XCStringModel.self, from: Data(contentsOf:
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
        writeDebouncer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            guard let self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
                let data = try encoder.encode(self.model)
                try data.write(to: self.target.xcstringURL)
            } catch {
                print(error)
            }
        })
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
        guard !isRunning else { return }
        processMessage = nil
        isRunning = true

        Task { @MainActor in
            for key in self.model.strings.map(\.key) {
                processMessage = .init(message: "🟡\(key)🟡: Start", success: true)
                do {
                    try await self.request(key)
                } catch {
                    processMessage = .init(message: "🔴\(key)🔴: \(error.localizedDescription)", success: false)
                }
            }
            processMessage = .init(message: "🟢All finished", success: true)
            isRunning = false
        }
    }

    func startKey(_ key: String) {
        guard !isRunning else { return }
        processMessage = nil
        isRunning = true

        Task { @MainActor in
            processMessage = .init(message: "🟡\(key)🟡: Start", success: true)
            do {
                try await self.request(key)
            } catch {
                processMessage = .init(message: "🔴\(key)🔴: \(error.localizedDescription)", success: false)
            }
            isRunning = false
        }
    }

    func removeKey(_ key: String) {
        model.strings.removeValue(forKey: key)
    }

    func removeAllTranslated(_ key: String) {
        model.strings[key]?.localizations.map(\.key).forEach { lang in
            if lang != baseLang {
                model.strings[key]?.localizations[lang] = .init(stringUnit: .init(state: "needs_review", value: ""))
            }
        }
    }

    func stop() {
        eventSource = nil
        isRunning = false
    }
}

private extension GPTService {
    func generateRequestMessages(_ key: String) throws -> [[String: String]] {
        guard let locStr = model.strings[key] else {
            throw "unexpected error key: \"\(key)\""
        }
        var baseText: String?
        if let _baseText = locStr.localizations[baseLang],
           !_baseText.stringUnit.value.isEmpty {
            baseText = _baseText.stringUnit.value
        } else if baseLang == model.sourceLanguage {
            baseText = key
        }
        if baseText?.nilIfEmpty == nil {
            throw "empty string in \"\(baseLang)\" for Key: \"\(key)\""
        }
        var jsonDict: [String: String] = [:]
        jsonDict["raw"] = baseText
        jsonDict[baseLang] = baseText
        langs.forEach { lang in
            if lang != baseLang, locStr.localizations[lang]?.stringUnit.value.nilIfEmpty == nil {
                jsonDict[lang] = ""
            }
        }
        if locStr.localizations[baseLang]?.stringUnit.value.nilIfEmpty != nil, jsonDict.count == 2 {
            throw "no language needs to be translated!"
        }

        let jsonStr = String(data: try! JSONSerialization.data(withJSONObject: jsonDict), encoding: .utf8)!
        let prompt = "我会给你一个json，你将会对json中key对应的语言进行i18n翻译到空白的json value中。请基于我给你的json中的'\(baseLang)'的value结合'raw'中的value作为基准给出符合本地化用词习惯的翻译结果。"

        var messages: [[String: String]] = []
        messages.append(["role": "system", "content": prompt])
        messages.append(["role": "user", "content": jsonStr])

        return messages
    }

    func parseMessage(_ message: String) -> String {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let regexStr = #"(?<=\{"content":").*(?="\})"#
        let regex = try! NSRegularExpression(pattern: regexStr)
        let text = regex
            .matches(in: message, range: NSRange(location: 0, length: message.count))
            .map { (message as NSString).substring(with: $0.range) }
            .joined()
        return text
    }

    func handleGPTResponse(text: String, for key: String) throws {
        let pattern = "\\{.*\\}"
        guard let range = text.range(of: pattern, options: .regularExpression) else {
            throw "JSON string not found in the input."
        }
        let jsonString = String(text[range]).replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\\n", with: "")
        print(jsonString)
        var dict = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as! [String: String]
        if dict["en"]?.nilIfEmpty == nil {
            dict["en"] = dict["raw"]
        }
        var translated: [String] = []
        dict.sorted(by: { $0.key < $1.key })
            .filter { langs.contains($0.key) }
            .forEach { lang, value in
                var locStr = model.strings[key] ?? LocalizationString(extractionState: "manual")
                if locStr.localizations[lang]?.stringUnit.value.nilIfEmpty == nil {
                    locStr.localizations[lang] = .init(stringUnit: .init(state: "translated", value: key.isFirstCharCapitalized ? value.firstCharCapitalized : value))
                    translated.append(lang)
                }
                model.strings[key] = locStr
            }
        processMessage = .init(message: "\(key) >>> \(translated.joined(separator: ", "))", success: true)
    }

    @MainActor
    func request(_ key: String) async throws {
        let setting = SettingService.shared
        if setting.gptAPIKey.isEmpty {
            throw "empty GPT API Key, config it in Settings."
        }

        let messages = try generateRequestMessages(key)
        let body: [String: Any] = ["model": setting.model,
                                   "stream": true,
                                   "messages": messages]

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
        urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(setting.gptAPIKey)",
                                          "Accept": "text/event-stream",
                                          "Content-Type": "application/json"]

        print(urlRequest.cURL())

        let eventSource = EventSource()
        self.eventSource = eventSource
        defer {
            self.eventSource = nil
        }
        let dataTask = eventSource.dataTask(for: urlRequest)

        var text = ""
        for await event in dataTask.events() {
            switch event {
            case .open:
                print("Connection was opened.")
            case let .error(error):
                print("Received an error:", error.localizedDescription)
                throw error
            case let .message(message):
                text.append(parseMessage(message.data ?? ""))
            case .closed:
                print("Connection was closed.")
                try handleGPTResponse(text: text, for: key)
                return
            }
        }
    }
}
