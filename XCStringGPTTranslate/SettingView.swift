//
//  SettingView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) var dismiss
    @State var service = SettingService.shared

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("GPT host")
                        .frame(width: 80, alignment: .trailing)
                    TextField("GPT host", text: $service.gptServer)
                }
                HStack {
                    Text("GPT API Key")
                        .frame(width: 80, alignment: .trailing)
                    TextField("GPT API Key", text: $service.gptAPIKey)
                }

                HStack {
                    Text("Model")
                        .frame(width: 80, alignment: .trailing)
                    Picker("", selection: $service.model) {
                        ForEach(service.modelList, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }

                Button("Close") {
                    dismiss()
                }
                .padding(20)
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
