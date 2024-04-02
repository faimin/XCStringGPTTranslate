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
            if lang != baseLang {
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
    func generateRequestMessages(_ key: String) throws -> [[String: String]] {
        guard let locStr = model.strings[key] else {
            throw "unexpected error key: \"\(key)\""
        }
        var baseText: String?
        if baseLang == "Comment" {
            baseText = locStr.comment
        } else if let _baseText = locStr.localizations[baseLang],
                  _baseText.stringUnit?.value.nilIfEmpty != nil {
            baseText = _baseText.stringUnit!.value
        } else if baseLang == model.sourceLanguage {
            baseText = key
        }
        guard let staticBaseText = baseText?.nilIfEmpty else {
            throw "empty string in \"\(baseLang)\" for Key: \"\(key)\""
        }
        var jsonDict: [String: String] = [:]
        langs.forEach { lang in
            if lang != baseLang, locStr.localizations[lang]?.stringUnit?.value.nilIfEmpty == nil {
                jsonDict[lang] = ""
            }
        }
        if locStr.localizations[baseLang]?.stringUnit?.value.nilIfEmpty != nil, jsonDict.count == 2 {
            throw "no language needs to be translated!"
        }

        let jsonStr = String(data: try! JSONSerialization.data(withJSONObject: jsonDict), encoding: .utf8)!
        let prompt = "请将json中key对应的语言进行符合当地用词习惯的翻译到空白的json value中。翻译的内容是：\"\"\"\n\(staticBaseText)\n\"\"\""

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
        if dict[baseLang]?.nilIfEmpty == nil, baseLang == model.sourceLanguage {
            dict[baseLang] = key
        }
        var translated: [String] = []
        dict.sorted(by: { $0.key < $1.key })
            .filter { langs.contains($0.key) }
            .forEach { lang, value in
                var locStr = model.strings[key] ?? .init(extractionState: "manual")
                if locStr.localizations[lang]?.stringUnit?.value.nilIfEmpty == nil {
                    locStr.localizations[lang] = .init(stringUnit: .init(state: "translated", value: key.isFirstCharCapitalized ? value.firstCharCapitalized : value))
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
