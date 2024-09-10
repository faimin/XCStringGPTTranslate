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

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 0) {
                    HStack {
                        Text("GPT API Key")
                            .frame(width: 80, alignment: .trailing)
                        SecureField("API Key", text: $settingService.gptAPIKey)
                    }
                    .frame(height: 44)

                    HStack {
                        Text("OpenAI endpoint (Optional)")
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

                Spacer()
            }
            .padding(24)
            .frame(width: 400, height: 300)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingView()
}
