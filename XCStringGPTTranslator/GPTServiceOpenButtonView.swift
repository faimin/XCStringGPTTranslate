//
//  GPTServiceOpenButtonView.swift
//  XCStringGPTTranslate
//
//  Created by wp on 2024/2/27.
//

import SwiftUI

struct GPTServiceOpenButtonView: View {
    @Binding private var target: GPTServiceTarget?
    @State private var xcstringsURL: URL?
    @State private var projURL: URL?

    init(target: Binding<GPTServiceTarget?>) {
        _target = target
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Open .xcodeproj") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.init(importedAs: "xcodeproj")]
                    if panel.runModal() == .OK, let url = panel.url {
                        projURL = url
                    }
                }
                if let projURL {
                    Text(projURL.path(percentEncoded: false))
                }
            }

            HStack {
                Button("Open .xcstrings") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.init(importedAs: "xcstrings")]
                    if panel.runModal() == .OK, let url = panel.url {
                        xcstringsURL = url
                    }
                }
                if let xcstringsURL {
                    Text(xcstringsURL.path(percentEncoded: false))
                }
            }
        }
        .onChange(of: xcstringsURL) { _, newValue in
            if let newValue, let projURL {
                target = .init(xcstringURL: newValue, xcprojURL: projURL)
            }
        }
        .onChange(of: projURL) { _, newValue in
            if let newValue, let xcstringsURL {
                target = .init(xcstringURL: xcstringsURL, xcprojURL: newValue)
            }
        }
    }
}
