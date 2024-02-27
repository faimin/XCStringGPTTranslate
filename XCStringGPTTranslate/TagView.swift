//
//  TagView.swift
//  XCStringGPTTranslate
//
//  Created by wp on 2024/2/27.
//

import Foundation
import SwiftUI

struct TagView: View {
    var title: String
    var onClick: () -> Void
    var onClose: () -> Void

    @State private var showCloseButton: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
            Spacer()
        }
        .background(Color.gray.opacity(0.001))
        .truncationMode(.head)
        .lineLimit(1)
        .frame(alignment: .leading)
        .padding(5)
        .overlay(alignment: .trailing) {
            if showCloseButton {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
        }
        .onTapGesture {
            onClick()
        }
//        .onHover { b in
//            showCloseButton = b
//        }
    }
}

#Preview {
    struct Content: View {
        let array = [
            "Mystical" + "Mystical",
            "Serendipity" + "Serendipity",
            "Luminous" + "Luminous",
            "Cascade" + "Cascade",
            "Whimsical" + "Whimsical",
        ]
        @State var selected: String? = "Mystical"

        var body: some View {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 1) {
                    ForEach(array, id: \.self) { title in
                        TagView(title: "N", onClick: {
                            selected = title
                        }, onClose: {})
                            .frame(width: 100)
                            .background {
                                if selected == title {
                                    Color.green
                                } else {
                                    Color.gray.opacity(0.1)
                                }
                            }
                    }

                    Spacer()
                }
                Divider()

                Color.yellow
            }
        }
    }
    return Content()
}
