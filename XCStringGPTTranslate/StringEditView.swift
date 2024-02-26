//
//  StringEditView.swift
//  GPTxcstringTranslate
//
//  Created by winddpan on 2024/2/26.
//

import SwiftUI

struct StringEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var text: String
    @State var editintText: String = ""

    init(_ text: Binding<String>) {
        _text = text
        _editintText = .init(initialValue: text.wrappedValue)
    }

    var body: some View {
        VStack {
            TextEditor(text: $editintText)
                .foregroundStyle(Color.green)
                .frame(width: 300, height: 200)
                .lineSpacing(5)

            HStack(spacing: 12) {
                Button("Close") {
                    dismiss()
                }

                Button("Save") {
                    text = editintText
                    dismiss()
                }
            }
        }
        .padding()
    }
}

#Preview {
    struct Content: View {
        @State var text = "123123123\n123123123123123"
        var body: some View {
            StringEditView($text)
        }
    }

    return Content()
}
