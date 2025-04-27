//
//  ContentView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SettingsAccess
import SwiftUI

struct ContentView: View {
    @Environment(\.openSettings) private var openSettings: OpenSettingsAction
    @State private var gptServices: [GPTService] = []
    @State private var selectGptServicesTarget: GPTServiceTarget?
    @State private var rootDirectory: URL?
    @State private var noXcprojTip = false
    @State private var noXcstringsTip = false
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            Color.clear

            if gptServices.isEmpty {
                openView
            } else {
                contentView
            }
        }
        .navigationTitle("XCStrings GPT translator")
    }

    @ViewBuilder
    var openView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill()
                .opacity(0.1)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .opacity(0.5)
                }
                .padding(20)

            VStack(spacing: 40) {
                Text("Drag and Drop Project directory")
                    .font(.title)

                Button("Open Xcode Project directory") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = true
                    panel.allowedContentTypes = [.directory]
                    if panel.runModal() == .OK, let url = panel.url {
                        tryOpenDirectory(url)
                    }
                }
            }
        }
        .dropDestination(for: URL.self) { receivedTitles, _ in
            if let first = receivedTitles.first {
                return tryOpenDirectory(first)
            }
            return false
        }
        .alert("Open your Project root directory!", isPresented: $noXcprojTip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Can't find .xcodeproj in this directory!")
        }
        .alert("Open your Project root directory!", isPresented: $noXcstringsTip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Can't find .xcstrings in your project's directory!")
        }
    }

    @discardableResult
    private func tryOpenDirectory(_ url: URL) -> Bool {
        rootDirectory = url

        var xcproj: URL?
        var xcstrings: [URL] = []
        let directoryEnum = FileManager.default.enumerator(atPath: url.path)
        while let filePath = directoryEnum?.nextObject() as? String {
            if filePath.hasSuffix(".xcstrings") {
                xcstrings.append(url.appending(component: filePath))
            } else if filePath.hasSuffix(".xcodeproj") {
                let find = url.appending(component: filePath)
                if xcproj == nil {
                    xcproj = find
                } else if let _xcproj = xcproj, find.pathComponents.count < _xcproj.pathComponents.count {
                    xcproj = find
                }
            }
        }
        if let xcproj, !xcstrings.isEmpty {
            let gptServices = xcstrings.compactMap { xcstringURL in
                do {
                    return try GPTService(target: GPTServiceTarget(xcstringURL: xcstringURL, xcprojURL: xcproj))
                } catch {
                    print(error)
                    return nil
                }
            }
            if !gptServices.isEmpty {
                self.gptServices = gptServices
                return true
            }
        }
        if xcproj == nil {
            noXcprojTip = true
        } else if xcstrings.isEmpty {
            noXcstringsTip = true
        }
        return false
    }

    @ViewBuilder
    private var contentView: some View {
        NavigationSplitView {
            VStack(alignment: .leading) {
                List(gptServices.map(\.target), selection: $selectGptServicesTarget) { target in
                    let title = target.xcstringURL.absoluteString
                        .replacingOccurrences(of: rootDirectory?.absoluteString ?? "", with: "")
                        .replacingOccurrences(of: "file://", with: "")
                    NavigationLink(value: target) {
                        Text(title)
                            .lineLimit(0)
                    }
                }

                Button(action: {
                    openSettings()
                }, label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                })
                .padding(8)
            }

        } detail: {
            if let selectGptServicesTarget, let service = gptServices.first(where: { $0.target == selectGptServicesTarget }) {
                let title = selectGptServicesTarget.xcstringURL.absoluteString
                    .replacingOccurrences(of: rootDirectory?.absoluteString ?? "", with: "")
                    .replacingOccurrences(of: "file://", with: "")

                GPTProcessView(gptService: service, searchText: $viewModel.debounceSearchText)
                    .id(service.target.hashValue)
                    .navigationTitle(title)
            }
        }
        .onAppear(perform: {
            if selectGptServicesTarget == nil {
                selectGptServicesTarget = gptServices.first?.target
            }
        })
        .searchable(text: $viewModel.searchText, isPresented: Binding.constant(true), placement: SearchFieldPlacement.automatic, prompt: "Please input search keywords")
    }
}

#Preview {
    ContentView()
}
