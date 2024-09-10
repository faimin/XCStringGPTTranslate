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
    private var eventSource: EventSource?
    @ObservationIgnored
    private var dataTask: EventSource.DataTask?

    @ObservationIgnored
    private var writeDebouncer: Timer?

    init(target: GPTServiceTarget) throws {
        self.target = target
        model = .init(sourceLanguage: "en", strings: [:], version: "1.0")
        baseLang = ""
        base2Lang = ""
        langs = []
        try reload()
    }

    func reload() throws {
        let model = try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf:
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
                let data = try encoder.encode(model)
                try data.write(to: target.xcstringURL)
            } catch {
                print(error)
            }
        })
    }

    private func updateLangsList() {
        var langs = langs
        for i in 0 ..< langs.count {
            if langs[i] == base2Lang {
                langs.remove(at: i)
                langs.insert(base2Lang, at: 0)
                break
            }
        }
        for i in 0 ..< langs.count {
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
                processMessage = .init(message: "\(failureCount == 0 ? "🟢" : "🔴")Succeessed: \(successCount)  Failure: \(failureCount)", success: failureCount == 0)
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
        eventSource = nil
        isRunning = false
    }
}

private extension GPTService {
    private func getLangText(_ lang: String, key: String) -> String? {
        guard let locStr = model.strings[key] else {
            return nil
        }
        let str: String?
        if lang == "Comment" {
            str = locStr.comment
        } else if let text = locStr.localizations[lang],
                  text.stringUnit?.value.nilIfEmpty != nil {
            str = text.stringUnit!.value
        } else if lang == model.sourceLanguage {
            str = key
        } else {
            str = nil
        }
        return str
    }

    func generateRequestMessages(_ key: String) throws -> [[String: String]] {
        guard let locStr = model.strings[key] else {
            throw "unexpected error key: \"\(key)\""
        }

        let baseText: String? = getLangText(baseLang, key: key)
        let base2Text: String? = getLangText(base2Lang, key: key)
        if baseText?.nilIfEmpty == nil, base2Text?.nilIfEmpty == nil {
            throw "empty string in \"\(baseLang)\" for Key: \"\(key)\""
        }
        let sourceText = [baseText, base2Text].compactMap { $0?.nilIfEmpty }
        let sourceTextJSON = String(data: try! JSONSerialization.data(withJSONObject: sourceText), encoding: .utf8)!

        var toLangs: [String: String] = [:]
        langs.forEach { lang in
            if locStr.localizations[lang]?.stringUnit?.value.nilIfEmpty == nil {
                toLangs[lang] = ""
            }
        }
        if toLangs.isEmpty {
            throw "no language needs to be translated!"
        }
        let toLangJSON = String(data: try! JSONSerialization.data(withJSONObject: toLangs), encoding: .utf8)!

        let prompt = """
        #需要翻译的文字，它们在不同语言中都是一个意思
        \(sourceTextJSON)

        #结合以上的意思翻译成json中key对应的语言填写到空白的json value中。
        \(toLangJSON)
        """

        var messages: [[String: String]] = []
        messages.append(["role": "system", "content": prompt])
        return messages
    }

    func parseMessage(_ message: String) -> String {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let regexStr = #"(?<="content":\s?")(.*?)(?<!\\)(?=")"#
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
        if dict[baseLang]?.nilIfEmpty == nil, baseLang == model.sourceLanguage {
            dict[baseLang] = key
        }
        var translated: [String] = []
        dict.sorted(by: { $0.key < $1.key })
            .filter { langs.contains($0.key) }
            .forEach { lang, value in
                var locStr = model.strings[key] ?? .init(extractionState: "manual")
                if locStr.localizations[lang]?.stringUnit?.value.nilIfEmpty == nil {
                    var fixedValue = value
                    if key.isFirstCharCapitalized {
                        fixedValue = fixedValue.firstCharCapitalized
                    }
                    let rawCapitalizedComps = key.components(separatedBy: " ").filter { $0.isFirstCharCapitalized }
                    rawCapitalizedComps.forEach { string in
                        fixedValue = fixedValue.replacingOccurrences(of: string.lowercased(), with: string)
                    }
                    locStr.localizations[lang] = .init(stringUnit: .init(state: "translated", value: fixedValue))
                    translated.append(lang)
                }
                model.strings[key] = locStr
            }
        processMessage = .init(message: "\(key)  <<< \(translated.joined(separator: ", "))", success: true)
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
            self.dataTask = nil
        }
        let dataTask = eventSource.dataTask(for: urlRequest)
        self.dataTask = dataTask

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
