//
//  SettingView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) var dismiss
    @State var settingService = SettingService.shared
    @State private var testConnectionOK: Bool?    = nil
    @State private var refreshModelsOK: Bool?     = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Provider")
                            .frame(width: 80, alignment: .trailing)
                        Picker("", selection: $settingService.apiProvider) {
                            ForEach(SettingService.APIProvider.allCases) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: settingService.apiProvider) { old, newProvider in
                            if newProvider == .lmStudio {
                                Task {
                                    testConnectionOK = await settingService.testLMStudioConnection()
                                    await settingService.fetchLMStudioModels()
                                    refreshModelsOK = !settingService.lmStudioModels.isEmpty
                                }
                            }
                        }
                    }
                    .frame(height: 44)

                    if settingService.apiProvider == .openAI {
                        HStack {
                            Text("API Key")
                                .frame(width: 80, alignment: .trailing)
                            SecureField("API Key", text: $settingService.gptAPIKey)
                        }
                        .frame(height: 44)
                        HStack {
                            Text("OpenAI endpoint (Optional)")
                                .frame(width: 80, alignment: .trailing)
                            TextField("https://api.openai.com", text: $settingService.gptServer)
                                .disableAutocorrection(true)
                                .textContentType(.URL)
                        }
                        .frame(height: 44)
                        HStack {
                            Text("Model")
                                .frame(width: 80, alignment: .trailing)
                            Picker("", selection: $settingService.model) {
                                ForEach(settingService.modelList, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                        }
                        .frame(height: 44)
                    }
                    
                    else {
                        HStack {
                            Text("URL")
                                .frame(width: 80, alignment: .trailing)
                            TextField("http://localhost:1234", text: $settingService.lmStudioURL)
                                .disableAutocorrection(true)
                                .textContentType(.URL)
                        }
                        .frame(height: 44)
                        HStack(spacing: 16) {
                            Button("Test Connection") {
                                Task {
                                    let ok = await settingService.testLMStudioConnection()
                                    testConnectionOK = ok
                                }
                            }
                            if let ok = testConnectionOK {
                                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(ok ? Color.green : Color.red)
                            }

                            Button("Refresh Models") {
                                Task {
                                    await settingService.fetchLMStudioModels()
                                    refreshModelsOK = !settingService.lmStudioModels.isEmpty
                                }
                            }
                            if let ok = refreshModelsOK {
                                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(ok ? Color.green : Color.red)
                            }
                        }
                        .frame(height: 44)
                        HStack {
                            Text("Model")
                                .frame(width: 80, alignment: .trailing)
                            Picker("", selection: $settingService.lmStudioModel) {
                                ForEach(settingService.lmStudioModels, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                        }
                        .frame(height: 44)
                    }
                }

                Spacer()
            }
            .padding(24)
            .task {
                if settingService.apiProvider == .lmStudio {
                    testConnectionOK   = await settingService.testLMStudioConnection()
                    await settingService.fetchLMStudioModels()
                    refreshModelsOK    = !settingService.lmStudioModels.isEmpty
                }
            }
            
            .frame(width: 400, height: 300)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingView()
}
