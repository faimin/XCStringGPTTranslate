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
    let key: String
    let lang: String

    init(key: String, lang: String, text: Binding<String>) {
        self.key = key
        self.lang = lang
        _text = text
        _editintText = .init(initialValue: text.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(key)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .lineSpacing(5)

                TextEditor(text: $editintText)
                    .lineSpacing(5)

                HStack(spacing: 20) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Close")
                            .padding(4)
                    })

                    Button(action: {
                        text = editintText
                        dismiss()
                    }, label: {
                        Text("Save")
                            .padding(4)
                            .foregroundStyle(Color.green)
                    })

                    Button(action: {
                        text = ""
                        dismiss()
                    }, label: {
                        Text("Delete")
                            .padding(4)
                            .foregroundStyle(Color.red)
                    })
                }
            }
            .frame(width: 400, height: 350)
            .padding()
            .navigationTitle(lang)
        }
    }
}

#Preview {
    struct Content: View {
        @State var text = "123123123\n123123123123123"
        var body: some View {
            StringEditView(key: "test", lang: "en", text: $text)
        }
    }

    return Content()
}
