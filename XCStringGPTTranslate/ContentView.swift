//
//  ContentView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("xcstringsPaths")
    private var xcstringsPaths: [String] = []

    @State var gptServices: [GPTService?] = [] {
        didSet {
            xcstringsPaths = gptServices.map { $0?.fileUrl.absoluteString ?? "" }
        }
    }

    @State var showSetting = false
    @State var selectedIndex: Int = 0

    var body: some View {
        _body
            .onAppear(perform: {
                if xcstringsPaths.count != gptServices.count {
                    gptServices = xcstringsPaths.map { path in
                        if let url = URL(string: path) {
                            return try? GPTService(fileUrl: url)
                        }
                        return nil
                    }
                }
            })
    }

    @ViewBuilder
    var _body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 1) {
                ForEach(gptServices.indices, id: \.self) { index in
                    let service = gptServices[index]

                    let title: String = {
                        if let text = service?.fileUrl.absoluteString.replacingOccurrences(of: "file://", with: "") {
                            var comps = text.components(separatedBy: "/")
                            comps.removeLast()
                            return comps.joined(separator: "/")
                        }
                        return "New"
                    }()

                    TagView(title: title) {
                        selectedIndex = index
                    } onClose: {
                        if gptServices.count > selectedIndex {
                            gptServices.remove(at: selectedIndex)
                        }
                        selectedIndex = 0
                    }
                    .frame(height: 30)
                    .frame(minWidth: 30, maxWidth: 200)
                    .background(selectedIndex == index ? Color.green.opacity(0.3) : Color.gray.opacity(0.1))
                }

                Button("+") {
                    xcstringsPaths.append("")
                    gptServices.append(nil)
                    selectedIndex = gptServices.count - 1
                }
                .font(.system(size: 18))
                .padding(.horizontal, 10)

                Spacer()

                Button(action: {
                    showSetting = true
                }, label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                })
                .sheet(isPresented: $showSetting) {
                    SettingView()
                }
            }
            Divider()

            if gptServices.count > selectedIndex {
                if let service = gptServices[selectedIndex] {
                    GPTProcessView(gptService: service)
                        .id(service.fileUrl.hashValue)
                } else {
                    ZStack {
                        Color.clear
                        Button("Open .xcstrings") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            panel.allowedContentTypes = [.init(importedAs: "xcstrings")]
                            if panel.runModal() == .OK, let url = panel.url {
                                do {
                                    print(url)
                                    gptServices[selectedIndex] = try GPTService(fileUrl: url)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
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
