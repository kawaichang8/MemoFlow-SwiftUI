//
//  MemoEditorView.swift
//  MemoFlow
//
//  巨大テキストエディタ - 究極ミニマルの入力エリア
//

import SwiftUI

struct MemoEditorView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    // 巨大フォント設定
    private let fontSize: CGFloat = 26
    private let lineSpacing: CGFloat = 12
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // プレースホルダー（優しく表示）
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: fontSize, weight: .light, design: .rounded))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 14)
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
                .padding(.horizontal, 6)
                .padding(.vertical, 10)
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
        Color.appBackground.ignoresSafeArea()
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
        Color.appBackground.ignoresSafeArea()
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
        Color.appBackground.ignoresSafeArea()
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
