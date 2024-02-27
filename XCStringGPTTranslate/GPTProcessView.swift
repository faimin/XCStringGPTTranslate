//
//  GPTProcessView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct GPTProcessView: View {
    @State var gptService: GPTService
    @State var hoverStringKey: String?
    @State var editingKeyLang: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            listContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var listContent: some View {
        let keys = gptService.model.strings.keys.sorted()

        ScrollView(.horizontal) {
            List {
                Section {
                    ForEach(keys, id: \.self) { key in
                        HStack(alignment: .top, spacing: 20) {
                            HStack {
                                let translatedCount = gptService.model.strings[key]!.localizations.values.compactMap {
                                    $0.stringUnit.value.isEmpty ? nil : $0
                                }
                                let lack = gptService.langs.count - translatedCount.count
                                if lack > 0 {
                                    Text("-\(lack)").foregroundStyle(Color.red)
                                        .frame(width: 30)
                                } else {
                                    Text("✓").foregroundStyle(Color.green)
                                        .frame(width: 30)
                                }
                                Text(key)
                                    .lineLimit(3)
                            }
                            .frame(width: 200, alignment: .leading)
                            .onHover { hover in
                                if hover, !gptService.isRunning {
                                    hoverStringKey = key
                                }
                            }
                            .overlay(alignment: .leading) {
                                if hoverStringKey == key {
                                    HStack {
                                        Button {
                                            hoverStringKey = nil
                                            if !gptService.isRunning {
                                                gptService.startKey(key)
                                            }
                                        } label: {
                                            Image(systemName: "arrowtriangle.right.circle.fill")
                                        }

                                        Button {
                                            hoverStringKey = nil
                                            if !gptService.isRunning {
                                                gptService.removeAllTranslated(key)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                        }
                                    }
                                }
                            }

                            ForEach(gptService.langs, id: \.self) { lang in
                                let keyLang = "\(lang)-\(key)"
                                let binding = Binding<String>(get: {
                                    gptService.model.strings[key]?.localizations[lang]?.stringUnit.value ?? ""
                                }, set: { newValue in
                                    var localized = gptService.model.strings[key] ?? LocalizationString()
                                    localized.extractionState = "manual"
                                    localized.localizations[lang] = I18nUnit(stringUnit: StringUnit(state: "translated", value: newValue))
                                    gptService.model.strings[key] = localized
                                })

                                Text(binding.wrappedValue)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .background(Color.gray.opacity(0.001))
                                    .id(keyLang)
                                    .onTapGesture {
                                        editingKeyLang = keyLang
                                    }
                                    .lineLimit(3)
                                    .font(.system(size: 13))
                                    .frame(width: 100, alignment: .leading)
                                    .sheet(isPresented: Binding<Bool>.init {
                                        editingKeyLang == keyLang
                                    } set: { show in
                                        if !show {
                                            editingKeyLang = nil
                                        }
                                    }) {
                                        StringEditView(key: key, lang: lang, text: binding)
                                    }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                } header: {
                    HStack(spacing: 20) {
                        let titles = ["Key"] + gptService.langs
                        ForEach(titles.indices, id: \.self) { idx in
                            let title = titles[idx]
                            HStack {
                                Text(title)
                                Spacer()
                                Divider()
                            }
                            .frame(width: idx == 0 ? 200 : 100, alignment: .center)
                        }
                    }
                }
            }
            .frame(width: CGFloat(120 * (gptService.langs.count + 1) + 120))
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 20) {
            if gptService.isRunning {
                Button(action: {
                    gptService.stop()
                }, label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color.red)
                })
            } else {
                Button(action: {
                    gptService.startAll()
                }, label: {
                    Image(systemName: "arrowtriangle.right.fill")
                })
            }

            Group {
                Button(action: {
                    try? gptService.reload()
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })

                Picker("Base", selection: $gptService.baseLang) {
                    ForEach(gptService.langs, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .frame(width: 120)
            }
            .disabled(gptService.isRunning)

            if let processMessage = gptService.processMessage {
                Text(processMessage.message)
                    .foregroundStyle(processMessage.success ? Color.green : Color.red)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

#Preview {
    do {
        let path = Bundle.main.url(forResource: "dev-xcstrings", withExtension: "json")
        let service = try GPTService(fileUrl: path!)
        return GPTProcessView(gptService: service)
    } catch {
        return Color.red
    }
}
