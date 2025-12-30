//
//  MemoEditorView.swift
//  MemoFlow
//
//  巨大テキストエディタ - 究極ミニマルの入力エリア
//  カスタムテーマ & フォントサイズ対応
//

import SwiftUI

struct MemoEditorView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    // ThemeManagerから設定を取得
    private var themeManager: ThemeManager { ThemeManager.shared }
    
    // フォント設定
    private var fontSize: CGFloat {
        themeManager.fontSize.mainTextSize
    }
    
    private var lineSpacing: CGFloat {
        themeManager.fontSize.lineSpacing
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // プレースホルダー（優しく表示）
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: fontSize, weight: .light, design: .rounded))
                    .foregroundStyle(themeManager.placeholderColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
            
            // テキストエディタ（巨大フォント、広い行間）
            TextEditor(text: $text)
                .font(.system(size: fontSize, weight: .regular, design: .default))
                .foregroundStyle(themeManager.textColor)
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
        ThemeManager.shared.backgroundColor.ignoresSafeArea()
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
}

#Preview("With Text - Large Font") {
    @Previewable @State var text = "これはサンプルテキストです。\n\n複数行にも対応しています。\n長い文章でも美しく表示されます。"
    @Previewable @FocusState var focused: Bool
    
    ZStack {
        ThemeManager.shared.backgroundColor.ignoresSafeArea()
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
    .onAppear {
        ThemeManager.shared.fontSize = .large
    }
}

#Preview("Sepia Theme") {
    @Previewable @State var text = "セピアテーマのプレビュー"
    @Previewable @FocusState var focused: Bool
    
    ZStack {
        Color(red: 0.96, green: 0.94, blue: 0.88).ignoresSafeArea()
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
    .onAppear {
        ThemeManager.shared.currentTheme = .sepia
    }
}

#Preview("Dark Theme") {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    
    ZStack {
        Color(white: 0.05).ignoresSafeArea()
        MemoEditorView(
            text: $text,
            isFocused: $focused,
            placeholder: "なんでも"
        )
        .padding()
    }
    .preferredColorScheme(.dark)
    .onAppear {
        ThemeManager.shared.currentTheme = .dark
    }
}
