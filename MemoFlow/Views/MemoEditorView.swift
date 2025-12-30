//
//  MemoEditorView.swift
//  MemoFlow
//
//  巨大テキストエディタ - 極限ミニマルの入力エリア
//

import SwiftUI

struct MemoEditorView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    // 巨大フォント設定
    private let fontSize: CGFloat = 28
    private let lineSpacing: CGFloat = 10
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // プレースホルダー（中央揃えで大きく）
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: fontSize, weight: .light, design: .rounded))
                    .foregroundStyle(Color.textTertiary.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
            
            // テキストエディタ（巨大フォント、広い行間）
            TextEditor(text: $text)
                .font(.system(size: fontSize, weight: .regular, design: .default))
                .lineSpacing(lineSpacing)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .focused(isFocused)
                .autocorrectionDisabled(false)
                .textInputAutocapitalization(.sentences)
                .scrollIndicators(.hidden)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused.wrappedValue = true
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    
    ZStack {
        Color.appBackground
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
}

#Preview("With Text") {
    @Previewable @State var text = "これはサンプルテキストです。\n\n複数行にも対応しています。\n長い文章でも美しく表示されます。"
    @Previewable @FocusState var focused: Bool
    
    ZStack {
        Color.appBackground
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
}

#Preview("Dark Mode") {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    
    ZStack {
        Color.appBackground
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
