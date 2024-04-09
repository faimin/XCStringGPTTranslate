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
    @State var storeService = StoreService.shared
    @State var busy = false
    @State var errorText: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 0) {
                    HStack {
                        Text("GPT API Key")
                            .frame(width: 80, alignment: .trailing)
                        TextField("API Key", text: $settingService.gptAPIKey)
                    }
                    .frame(height: 44)

                    HStack {
                        Text("OpenAI host (Optional)")
                            .frame(width: 80, alignment: .trailing)

                        let defaultUrl = "https://api.openai.com"
                        TextField(defaultUrl, text: $settingService.gptServer)
                    }
                    .frame(height: 44)

                    HStack {
                        Text("Model")
                            .frame(width: 80, alignment: .trailing)
                        Picker("", selection: $settingService.model) {
                            ForEach(settingService.modelList, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    }
                    .frame(height: 44)
                }
                .disabled(!storeService.isPurchased)

                if !storeService.isPurchased {
                    HStack {
                        Button(action: {
                            Task { @MainActor in
                                self.busy = true
                                do {
                                    try await storeService.restore()
                                } catch {
                                    print(error)
                                    self.errorText = error.localizedDescription
                                }
                                self.busy = false
                            }
                        }, label: {
                            Text("Restore")
                        })

                        Button(action: {
                            Task { @MainActor in
                                self.busy = true
                                do {
                                    try await storeService.purchase()
                                } catch {
                                    print(error)
                                    self.errorText = error.localizedDescription
                                }
                                self.busy = false
                            }
                        }, label: {
                            Text("Purchase To Unlock")
                                .foregroundStyle(Color.accentColor)
                        })
                    }
                    .disabled(busy)
                    .alert("Error",
                           isPresented: .init(get: { errorText != nil }, set: {
                               if !$0 {
                                   errorText = nil
                               }
                           }), actions: {
                               Button(role: .cancel, action: {}) {
                                   Text("OK")
                               }
                           }, message: {
                               Text(errorText ?? "")
                           })
                }

                Spacer()
            }
            .padding(24)
            .frame(width: 400, height: 300)
            .navigationTitle("Settings")
        }
        .onAppear(perform: {
            if !storeService.isPurchased {
                settingService.gptServer = ""
                settingService.gptAPIKey = ""
            }
        })
    }
}

#Preview {
    SettingView()
}
