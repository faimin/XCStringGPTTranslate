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
        ScrollView(.horizontal) {
            List {
                Section {
                    ForEach(gptService.model.strings.keys.sorted(), id: \.self) { key in
                        if let locStr = gptService.model.strings[key] {
                            HStack(alignment: .top, spacing: 20) {
                                HStack {
                                    let translatedCount = locStr.localizations.values.compactMap {
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
                                    ZStack(alignment: .leading) {
                                        Color.gray.opacity(0.001)
                                        Text(key)
                                            .lineLimit(3)
                                    }
                                }
                                .frame(width: 200)
                                .frame(minHeight: 30, maxHeight: .infinity)
                                .onHover { hover in
                                    if hover {
                                        if !gptService.isRunning {
                                            hoverStringKey = key
                                        }
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
                                                    .background(Circle().fill(Color(NSColor.lightGray)))
                                            }

                                            Button {
                                                hoverStringKey = nil
                                                if !gptService.isRunning {
                                                    gptService.removeAllTranslated(key)
                                                }
                                            } label: {
                                                Image(systemName: "arrow.clockwise.circle.fill")
                                                    .background(Circle().fill(Color(NSColor.lightGray)))
                                            }

                                            Spacer()

                                            Button {
                                                hoverStringKey = nil
                                                if !gptService.isRunning {
                                                    gptService.removeKey(key)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.red)
                                                    .background(Circle().fill(Color(NSColor.lightGray)))
                                            }
                                        }
                                        .buttonBorderShape(.circle)
                                        .font(.system(size: 18))
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
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
        let xcstrings = Bundle.main.url(forResource: "dev-xcstrings", withExtension: "json")
        let proj = URL(string: "/Users/wp/side-project/XCStringGPTTranslate/XCStringGPTTranslate.xcodeproj")!
        let service = try GPTService(target: GPTServiceTarget(xcstringURL: xcstrings!, xcprojURL: proj))
        return GPTProcessView(gptService: service)
    } catch {
        return Color.red
    }
}
