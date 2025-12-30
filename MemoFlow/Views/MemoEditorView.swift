//
//  MemoEditorView.swift
//  MemoFlow
//
//  巨大テキストエディタ - メインの入力エリア
//

import SwiftUI

struct MemoEditorView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // プレースホルダー
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 24, weight: .light, design: .default))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
            
            // テキストエディタ
            TextEditor(text: $text)
                .font(.system(size: 24, weight: .regular, design: .default))
                .scrollContentBackground(.hidden)
                .background(.clear)
                .focused(isFocused)
                .autocorrectionDisabled(false)
                .textInputAutocapitalization(.sentences)
        }
        .padding(4)
    }
}

// MARK: - Custom Text Field Style (Alternative)
struct MinimalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(.system(size: 24, weight: .regular))
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    
    MemoEditorView(
        text: $text,
        isFocused: $focused,
        placeholder: "何でも書いて、すぐ送る"
    )
    .frame(height: 400)
    .padding()
}

#Preview("With Text") {
    @Previewable @State var text = "これはサンプルテキストです。\n複数行にも対応しています。"
    @Previewable @FocusState var focused: Bool
    
    MemoEditorView(
        text: $text,
        isFocused: $focused,
        placeholder: "何でも書いて、すぐ送る"
    )
    .frame(height: 400)
    .padding()
}

