//
//  TagChipsView.swift
//  MemoFlow
//
//  AI提案タグチップ - Apple Notes/Bear風のミニマルデザイン
//

import SwiftUI

struct TagChipsView: View {
    let adoptedTags: [Tag]
    let suggestedTags: [Tag]
    let onToggle: (Tag) -> Void
    let onRemove: (Tag) -> Void
    
    private var hasContent: Bool {
        !adoptedTags.isEmpty || !suggestedTags.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー（タグがある場合のみ）
            if hasContent {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .medium))
                    Text("タグ")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
            }
            
            // タグチップ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 採用済みタグ
                    ForEach(adoptedTags) { tag in
                        AdoptedTagChip(
                            tag: tag,
                            onRemove: { onRemove(tag) }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                    // 提案タグ
                    ForEach(suggestedTags) { tag in
                        SuggestedTagChip(
                            tag: tag,
                            onTap: {
                                HapticManager.shared.lightTap()
                                onToggle(tag)
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
        .frame(height: hasContent ? 60 : 0)
        .clipped()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: adoptedTags.count)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: suggestedTags.count)
    }
}

// MARK: - Adopted Tag Chip (選択済み = 目立つオレンジ)
struct AdoptedTagChip: View {
    let tag: Tag
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 5) {
            // チェックマーク
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.adoptedTagText)
            
            // タグ名
            Text(tag.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.adoptedTagText)
            
            // 削除ボタン
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.adoptedTagText.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.adoptedTagBackground, Color.adoptedTagBackground.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.adoptedTagBackground.opacity(colorScheme == .dark ? 0.4 : 0.3), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Suggested Tag Chip (未選択 = 控えめグレー)
struct SuggestedTagChip: View {
    let tag: Tag
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                // タグ名
                Text(tag.name)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.suggestedTagText)
                
                // 追加アイコン
                Image(systemName: "plus.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .strokeBorder(Color.suggestedTagBorder, lineWidth: 1)
            )
            .background(
                Capsule()
                    .fill(Color.suggestedTagBackground.opacity(colorScheme == .dark ? 0.3 : 0.5))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Tag Settings Indicator
struct TagModeIndicator: View {
    let mode: TagAutoMode
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            
            Text(mode.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
    
    private var indicatorColor: Color {
        switch mode {
        case .autoAdopt:
            return .green
        case .suggestOnly:
            return .orange
        case .off:
            return .gray
        }
    }
}

// MARK: - Preview
#Preview("With Tags") {
    VStack {
        TagChipsView(
            adoptedTags: [
                Tag(name: "アイデア", state: .adopted),
                Tag(name: "タスク", state: .adopted)
            ],
            suggestedTags: [
                Tag(name: "重要", state: .suggested),
                Tag(name: "あとで", state: .suggested),
                Tag(name: "プロジェクト", state: .suggested)
            ],
            onToggle: { _ in },
            onRemove: { _ in }
        )
        
        Spacer()
    }
    .padding()
}

#Preview("Empty") {
    VStack {
        TagChipsView(
            adoptedTags: [],
            suggestedTags: [],
            onToggle: { _ in },
            onRemove: { _ in }
        )
        
        Text("タグなし")
            .foregroundStyle(.secondary)
        
        Spacer()
    }
    .padding()
}

#Preview("Only Suggested") {
    VStack {
        TagChipsView(
            adoptedTags: [],
            suggestedTags: [
                Tag(name: "買い物", state: .suggested),
                Tag(name: "学習", state: .suggested)
            ],
            onToggle: { _ in },
            onRemove: { _ in }
        )
        
        Spacer()
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack {
        TagChipsView(
            adoptedTags: [
                Tag(name: "アイデア", state: .adopted),
                Tag(name: "タスク", state: .adopted)
            ],
            suggestedTags: [
                Tag(name: "重要", state: .suggested),
                Tag(name: "あとで", state: .suggested),
                Tag(name: "メモ", state: .suggested)
            ],
            onToggle: { _ in },
            onRemove: { _ in }
        )
        
        Spacer()
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("Mode Indicators") {
    HStack(spacing: 12) {
        TagModeIndicator(mode: .autoAdopt)
        TagModeIndicator(mode: .suggestOnly)
        TagModeIndicator(mode: .off)
    }
    .padding()
}
