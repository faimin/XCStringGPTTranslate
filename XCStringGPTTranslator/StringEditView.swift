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

    let title: String
    let key: String
    let comment: String?

    init(title: String,
         key: String,
         comment: String?,
         text: Binding<String>) {
        self.title = title
        self.key = key
        self.comment = comment
        _text = text
        _editintText = .init(initialValue: text.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Text(title)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineSpacing(5)
                    .font(.system(size: 18, weight: .bold))
            }

            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 16) {
                    Text("Key")
                        .frame(width: 60, alignment: .trailing)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    Text(key)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(2)
                        .lineLimit(5)
                }

                if let comment = comment?.nilIfEmpty {
                    Divider()

                    HStack(alignment: .top, spacing: 16) {
                        Text("Comment")
                            .frame(width: 60, alignment: .trailing)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentColor)

                        Text(comment)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(2)
                            .lineLimit(5)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 0.5)
            )

            TextEditor(text: $editintText)
                .scrollContentBackground(.hidden)
                .lineSpacing(5)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(lineWidth: 0.5)
                )

            HStack(spacing: 20) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Cancel")
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
                    Text("Clear")
                        .padding(4)
                        .foregroundStyle(Color.red)
                })
            }
        }
        .frame(width: 400, height: 380)
        .padding()
    }
}

#Preview {
    struct Content: View {
        @State var text = "123123123\n123123123123123"
        var body: some View {
            StringEditView(title: "this is title", key: "this is key", comment: "this is comment this is comment this is comment this is comment", text: $text)
        }
    }

    return Content()
}
