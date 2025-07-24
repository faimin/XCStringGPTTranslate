//
//  SettingService.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import Foundation
import ObservableUserDefault
import Combine

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
    var modelList: [String] = ["gpt-4o-mini", "gpt-4o", "gpt-o1-mini", "gpt-o3-mini"]

    enum APIProvider: String, CaseIterable, Identifiable, Codable {
        case openAI = "openai"
        case lmStudio = "lmstudio"
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .openAI: return "ChatGPT"
            case .lmStudio: return "LM Studio"
            }
        }
    }
    @ObservableUserDefault(.init(key: "api-provider", defaultValue: APIProvider.openAI.rawValue, store: .standard))
    @ObservationIgnored private var apiProviderRaw: String
    var apiProvider: APIProvider {
        get { APIProvider(rawValue: apiProviderRaw) ?? .openAI }
        set { apiProviderRaw = newValue.rawValue }
    }

    @ObservableUserDefault(.init(key: "lmstudio-url", defaultValue: "http://localhost:1234", store: .standard))
    @ObservationIgnored var lmStudioURL: String
    @ObservableUserDefault(.init(key: "lmstudio-model", defaultValue: "", store: .standard))
    @ObservationIgnored var lmStudioModel: String
    var lmStudioModels: [String] = []

    /// Ping `/api/v1/models` to verify LM Studio is alive
    func testLMStudioConnection() async -> Bool {
        let base = lmStudioURL.hasSuffix("/") ? String(lmStudioURL.dropLast()) : lmStudioURL
        guard let url = URL(string: base + "/v1/models") else { return false }
        var req = URLRequest(url: url); req.httpMethod = "GET"
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    /// Fetch model list from LM Studio
    func fetchLMStudioModels() async {
        let base = lmStudioURL.hasSuffix("/") ? String(lmStudioURL.dropLast()) : lmStudioURL
        guard let url = URL(string: base + "/v1/models") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            struct ModelInfo: Codable { let id: String }
            struct ListResponse: Codable { let data: [ModelInfo] }
            let list = try JSONDecoder().decode(ListResponse.self, from: data)
            let ids = list.data.map(\.id)
            DispatchQueue.main.async {
                self.lmStudioModels = ids
                if !ids.contains(self.lmStudioModel) {
                    self.lmStudioModel = ids.first ?? ""
                }
            }
        } catch {
            print("LM Studio fetch error:", error)
        }
    }

    init() {
        if model.isEmpty || !modelList.contains(model) {
            model = modelList[0]
        }
    }
}

extension SettingService: @unchecked Sendable {}
