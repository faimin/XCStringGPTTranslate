//
//  ContentView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("targets")
    private var targets: [GPTServiceTarget?] = []

    @State private var gptServices: [GPTService?] = [] {
        didSet {
            targets = gptServices.map { $0?.target }
        }
    }

    @State private var showSetting = false
    @State private var selectedIndex: Int = 0

    var body: some View {
        _body
            .onAppear(perform: {
                if targets.count != gptServices.count {
                    gptServices = targets.map { target in
                        if let target {
                            return try? GPTService(target: target)
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
                        if let text = service?.target.xcstringURL.absoluteString.replacingOccurrences(of: "file://", with: "") {
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
                        .id(service.target.xcstringURL.hashValue)
                } else {
                    ZStack {
                        Color.clear
                        GPTServiceOpenButtonView(target: .init(get: {
                            gptServices[selectedIndex]?.target
                        }, set: { newValue in
                            if let newValue {
                                gptServices[selectedIndex] = try? GPTService(target: newValue)
                            }
                        }))
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
