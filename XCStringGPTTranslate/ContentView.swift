//
//  ContentView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct ContentView: View {
    @State var gptService: GPTService?
    @State var showSetting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Button("Open .xcstrings") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.init(importedAs: "xcstrings")]
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            print(url)
                            gptService = try GPTService(fileUrl: url)
                        } catch {
                            print(error)
                        }
                    }
                }

                Button(action: {
                    showSetting = true
                }, label: {
                    Image(systemName: "gearshape.fill")
                })
                .sheet(isPresented: $showSetting) {
                    SettingView()
                }

                Spacer()
            }
            .padding(20)

            if let gptService {
                GPTProcessView(gptService: gptService)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("xctrings GPT translate")
    }
}

#Preview {
    ContentView()
}
