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
    @State var selecteRows = Set<String>()
    @State var deleteConfirm = false

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
        Table(keys, selection: $selecteRows) {
            TableColumn("") { key in
                if let locStr = gptService.model.strings[key] {
                    Group {
                        let translatedCount = locStr.localizations.values.compactMap {
                            $0.stringUnit?.value.nilIfEmpty == nil ? nil : $0
                        }
                        let lack = gptService.langs.count - translatedCount.count
                        if lack > 0 {
                            Text("-\(lack)").foregroundStyle(Color.red)
                                .minimumScaleFactor(0.5)
                        } else {
                            Text("✓").foregroundStyle(Color.green)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }
            }
            .width(25)

            TableColumn("Key") { key in
                let keyLang = "\(key)-Key"
                let binding = Binding<String>(get: {
                    key
                }, set: { newValue in
                    guard newValue != key else { return }
                    let valueModel = gptService.model.strings[key]
                    gptService.model.strings[key] = nil
                    gptService.model.strings[newValue] = valueModel
                })
                
                Text(key)
                    .lineLimit(3)
                    .frame(alignment: .leading)
                    .id(keyLang)
                    .onTapGesture {
                        editingKeyLang = keyLang
                    }
                    .sheet(isPresented: Binding(get: {
                        editingKeyLang == keyLang
                    }, set: { show in
                        if !show {
                            editingKeyLang = nil
                        }
                    })) {
                        StringEditView(title: "Key", key: key, comment: nil, text: binding)
                    }
            }
            .width(ideal: 200)

            TableColumn("Comment") { key in
                let keyLang = "\(key)-Comment"
                let binding = Binding<String>(get: {
                    gptService.model.strings[key]?.comment ?? ""
                }, set: { newValue in
                    gptService.model.strings[key]?.comment = newValue.nilIfEmpty
                })

                Text(gptService.model.strings[key]?.comment ?? "")
                    .font(.system(size: 13))
                    .lineLimit(3)
                    // .underline(true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.001))
                    .id(keyLang)
                    .onTapGesture {
                        editingKeyLang = keyLang
                    }
                    .sheet(isPresented:
                        Binding<Bool> {
                            editingKeyLang == keyLang
                        } set: { show in
                            if !show {
                                editingKeyLang = nil
                            }
                        }
                    ) {
                        StringEditView(title: "Comment", key: key, comment: nil, text: binding)
                    }
            }
            .width(ideal: 100)

            TableColumnForEach(gptService.langs) { lang in
                TableColumn(lang) { key in
                    let keyLang = "\(lang)-\(key)"
                    let binding = Binding<String>(get: {
                        gptService.model.strings[key]?.localizations[lang]?.stringUnit?.value ?? ""
                    }, set: { newValue in
                        var localized = gptService.model.strings[key] ?? .init()
                        localized.extractionState = "manual"
                        localized.localizations[lang] = .init(stringUnit: StringUnit(state: .translated, value: newValue))
                        gptService.model.strings[key] = localized
                    })

                    Text(binding.wrappedValue)
                        .font(.system(size: 13))
                        .lineLimit(3)
                         // .underline(true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.001))
                        .id(keyLang)
                        .onTapGesture {
                            editingKeyLang = keyLang
                        }
                        .sheet(isPresented:
                            Binding<Bool> {
                                editingKeyLang == keyLang
                            } set: { show in
                                if !show {
                                    editingKeyLang = nil
                                }
                            }
                        ) {
                            StringEditView(title: lang,
                                           key: key,
                                           comment: gptService.model.strings[key]?.comment,
                                           text: binding)
                        }
                }
                .width(ideal: 100)
            }
        }
        .disabled(gptService.isRunning)
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
                .help("Start")
            } else {
                Button(action: {
                    gptService.startKeys(selecteRows.sorted())
                }, label: {
                    Image(systemName: "arrowtriangle.right.fill")
                })
                .disabled(selecteRows.isEmpty)
                .help("Stop")
            }

            Button(action: {
                selecteRows.forEach { key in
                    gptService.removeAllTranslated(key)
                }
            }, label: {
                Image(systemName: "eraser")
            })
            .disabled(gptService.isRunning || selecteRows.isEmpty)
            .help("Clear")

            Button(action: {
                deleteConfirm = true
            }, label: {
                if gptService.isRunning || selecteRows.isEmpty {
                    Image(systemName: "trash")
                } else {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                }
            })
            .disabled(gptService.isRunning || selecteRows.isEmpty)
            .help("Delete")
            .alert("Confirm Delete?", isPresented: $deleteConfirm, actions: {
                Button("Cancel", role: .cancel) {}
                Button("Confirm", role: .destructive) {
                    selecteRows.forEach { key in
                        gptService.removeKey(key)
                    }
                }
            }, message: {
                Text(selecteRows.sorted().joined(separator: "\n"))
            })

            Button(action: {
                try? gptService.reload()
                selecteRows = []
            }, label: {
                Image(systemName: "arrow.clockwise")
            })
            .help("Refresh")
            .disabled(gptService.isRunning)

            if let processMessage = gptService.processMessage {
                Text(processMessage.message)
                    .foregroundStyle(processMessage.success ? Color.green : Color.red)
            }

            Spacer()

            Group {
                Picker("Base", selection: $gptService.baseLang) {
                    ForEach(["Comment"] + gptService.langs, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .frame(width: 200)

                Picker("Base2", selection: $gptService.base2Lang) {
                    ForEach(["", "Comment"] + gptService.langs, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .frame(width: 200)
            }
            .disabled(gptService.isRunning)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

#Preview {
    do {
        let testBundle = Bundle(path: Bundle.main.path(forResource: "test", ofType: "bundle")!)!
        let xcstringURL = testBundle.url(forResource: "dev-xcstrings", withExtension: "json")
        let xcprojURL = testBundle.url(forResource: "XCStringGPTTranslate", withExtension: "xcodeproj")
        let service = try GPTService(target: GPTServiceTarget(xcstringURL: xcstringURL!, xcprojURL: xcprojURL!))
        return GPTProcessView(gptService: service)
    } catch {
        print(error)
        return Color.red
    }
}
