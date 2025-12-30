//
//  TagChipsView.swift
//  MemoFlow
//
//  AI提案タグチップ - 極限ミニマルの横スクロール
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
        // タグチップ（ヘッダーなし、横スクロール）
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 採用済みタグ
                ForEach(adoptedTags) { tag in
                    AdoptedTagChip(
                        tag: tag,
                        onRemove: { onRemove(tag) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .scale(scale: 0.85).combined(with: .opacity)
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
                        removal: .scale(scale: 0.85).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .frame(height: hasContent ? 50 : 0)
        .clipped()
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: adoptedTags.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: suggestedTags.count)
    }
}

// MARK: - Adopted Tag Chip (選択済み = 目立つアクセント)
struct AdoptedTagChip: View {
    let tag: Tag
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    private var accentColor: Color {
        Color.adoptedTagBackground
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // タグ名
            Text(tag.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            // 削除ボタン
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 18, height: 18)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(accentColor)
        )
        .shadow(color: accentColor.opacity(0.35), radius: 6, x: 0, y: 3)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Suggested Tag Chip (未選択 = 控えめ)
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
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                
                // 追加アイコン
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .strokeBorder(Color(.systemGray4), lineWidth: 1.5)
            )
            .background(
                Capsule()
                    .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.5 : 0.8))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
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
        Spacer()
        
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
        .padding(.horizontal)
        
        Spacer()
    }
    .background(Color.appBackground)
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
    .background(Color.appBackground)
}

#Preview("Only Suggested") {
    VStack {
        Spacer()
        
        TagChipsView(
            adoptedTags: [],
            suggestedTags: [
                Tag(name: "買い物", state: .suggested),
                Tag(name: "学習", state: .suggested),
                Tag(name: "メモ", state: .suggested)
            ],
            onToggle: { _ in },
            onRemove: { _ in }
        )
        .padding(.horizontal)
        
        Spacer()
    }
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack {
        Spacer()
        
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
        .padding(.horizontal)
        
        Spacer()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
