//
//  TagChipsView.swift
//  MemoFlow
//
//  AI提案タグチップ - 「流してスッキリ」の横スクロール
//

import SwiftUI

struct TagChipsView: View {
    let adoptedTags: [Tag]
    let suggestedTags: [Tag]
    let onToggle: (Tag) -> Void
    let onRemove: (Tag) -> Void
    var showPrivacyNote: Bool = false
    
    @State private var appeared = false
    
    private var hasContent: Bool {
        !adoptedTags.isEmpty || !suggestedTags.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // プライバシー注記（ローカルAI処理中の場合）
            if showPrivacyNote && hasContent {
                LocalAIPrivacyNote()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            tagScrollView
        }
        .animation(.easeOut(duration: 0.2), value: showPrivacyNote)
    }
    
    private var tagScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 採用済みタグ
                ForEach(Array(adoptedTags.enumerated()), id: \.element.id) { index, tag in
                    AdoptedTagChip(
                        tag: tag,
                        onRemove: { onRemove(tag) }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75)
                        .delay(Double(index) * 0.06),
                        value: appeared
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.7).combined(with: .opacity),
                        removal: .scale(scale: 0.7).combined(with: .opacity)
                    ))
                }
                
                // 提案タグ
                ForEach(Array(suggestedTags.enumerated()), id: \.element.id) { index, tag in
                    SuggestedTagChip(
                        tag: tag,
                        onTap: {
                            HapticManager.shared.lightTap()
                            onToggle(tag)
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75)
                        .delay(Double(adoptedTags.count + index) * 0.06),
                        value: appeared
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .scale(scale: 0.7).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .frame(height: hasContent ? 58 : 0)
        .clipped()
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: adoptedTags.count)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: suggestedTags.count)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
        }
    }
}

// MARK: - Adopted Tag Chip
struct AdoptedTagChip: View {
    let tag: Tag
    let onRemove: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var showCheckmark = true
    
    private var accentColor: Color {
        Color.adoptedTagBackground
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // チェックマーク（採用アニメーション）
            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .transition(.scale.combined(with: .opacity))
            }
            
            // タグ名
            Text(tag.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            // 削除ボタン
            Button(action: {
                HapticManager.shared.lightTap()
                onRemove()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 18, height: 18)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.25))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: accentColor.opacity(colorScheme == .dark ? 0.5 : 0.45), radius: 10, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            // チェックマークアニメーション
            showCheckmark = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - Suggested Tag Chip
struct SuggestedTagChip: View {
    let tag: Tag
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                // プラスアイコン
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
                
                // タグ名
                Text(tag.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .strokeBorder(
                        Color(.systemGray4).opacity(colorScheme == .dark ? 0.6 : 0.8),
                        lineWidth: 1.5
                    )
            )
            .background(
                Capsule()
                    .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.35 : 0.6))
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08),
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.91 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Local AI Privacy Note
struct LocalAIPrivacyNote: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.green)
            
            Text("デバイス上で処理")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.5 : 0.8))
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
    .background(Color.appBackground.ignoresSafeArea())
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
    .background(Color.appBackground.ignoresSafeArea())
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
    .background(Color.appBackground.ignoresSafeArea())
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
    .background(Color.appBackground.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
