//
//  HistoryView.swift
//  MemoFlow
//
//  送信履歴画面 - 軽いローカル履歴表示
//

import SwiftUI

// MARK: - History Sheet View
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = HistoryViewModel()
    
    /// 再編集コールバック（MainCaptureViewに渡す）
    var onReuse: ((Memo) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                if viewModel.isEmpty {
                    emptyView
                } else {
                    historyList
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                if !viewModel.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Menu {
                            Button(role: .destructive) {
                                viewModel.confirmClearAll()
                            } label: {
                                Label("全て削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .sheet(item: $viewModel.selectedItem) { item in
                HistoryDetailView(
                    item: item,
                    viewModel: viewModel,
                    onReuse: { memo in
                        dismiss()
                        onReuse?(memo)
                    }
                )
            }
            .alert("履歴を削除", isPresented: $viewModel.showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    viewModel.deleteItem()
                }
            } message: {
                Text("このメモを履歴から削除しますか？")
            }
            .alert("全履歴を削除", isPresented: $viewModel.showClearAllConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("全て削除", role: .destructive) {
                    viewModel.clearAllHistory()
                }
            } message: {
                Text("すべての履歴を削除しますか？この操作は取り消せません。")
            }
            .onAppear {
                viewModel.refreshHistory()
            }
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            Text("履歴はありません")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text("送信したメモがここに表示されます")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - History List
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.historyItems) { item in
                    HistoryItemRow(item: item) {
                        viewModel.selectItem(item)
                    } onDelete: {
                        viewModel.confirmDelete(item)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            viewModel.refreshHistory()
        }
    }
}

// MARK: - History Item Row
struct HistoryItemRow: View {
    let item: MemoHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 送信先アイコン
                Image(systemName: item.destination.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.destination.color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(item.destination.color.opacity(0.12))
                    )
                
                // コンテンツ
                VStack(alignment: .leading, spacing: 4) {
                    // プレビューテキスト
                    Text(item.preview)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // 日時 + タグ
                    HStack(spacing: 8) {
                        Text(item.formattedDate)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        if !item.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(item.tags.prefix(2)) { tag in
                                    Text("#\(tag.name)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color(.systemGray5))
                                        )
                                }
                                
                                if item.tags.count > 2 {
                                    Text("+\(item.tags.count - 2)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 矢印
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondaryBackground)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

// MARK: - History Detail View
struct HistoryDetailView: View {
    let item: MemoHistoryItem
    @Bindable var viewModel: HistoryViewModel
    var onReuse: ((Memo) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isEditing: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // メタ情報
                    HStack(spacing: 12) {
                        // 送信先
                        Label(item.destination.displayName, systemImage: item.destination.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(item.destination.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(item.destination.color.opacity(0.12))
                            )
                        
                        // 日時
                        Text(item.formattedDate)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    
                    // タグ
                    if !item.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(item.tags) { tag in
                                    Text("#\(tag.name)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .strokeBorder(Color(.systemGray4), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 本文
                    if viewModel.isEditMode {
                        TextEditor(text: $viewModel.editingContent)
                            .font(.system(size: 17))
                            .frame(minHeight: 200)
                            .focused($isEditing)
                            .onAppear {
                                isEditing = true
                            }
                    } else {
                        Text(item.content)
                            .font(.system(size: 17))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isEditMode {
                        Button("完了") {
                            isEditing = false
                            viewModel.isEditMode = false
                        }
                    } else {
                        Menu {
                            Button {
                                viewModel.startEditing()
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            
                            Button {
                                if let memo = viewModel.copyToCapture() {
                                    onReuse?(memo)
                                }
                            } label: {
                                Label("新規メモとして使用", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                viewModel.confirmDelete(item)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 再送信ボタン
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        if viewModel.isEditMode {
                            Button {
                                viewModel.cancelEditing()
                            } label: {
                                Text("キャンセル")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemGray5))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button {
                            Task {
                                await viewModel.resend()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isSending {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("再送信")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(item.destination.color)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSending || viewModel.editingContent.isEmpty)
                        .opacity(viewModel.editingContent.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.appBackground)
                }
            }
            .alert("履歴を削除", isPresented: $viewModel.showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    viewModel.deleteItem()
                    dismiss()
                }
            } message: {
                Text("このメモを履歴から削除しますか？")
            }
        }
    }
}

// MARK: - Previews
#Preview {
    HistoryView()
}

#Preview("Item Row") {
    VStack {
        HistoryItemRow(
            item: {
                let item = MemoHistoryItem(
                    content: "明日のミーティングの資料を準備する。プレゼンスライドを更新して、関係者に送付。",
                    tags: [Tag(name: "タスク"), Tag(name: "仕事")],
                    destination: .todoist
                )
                return item
            }(),
            onTap: {},
            onDelete: {}
        )
        
        HistoryItemRow(
            item: {
                let item = MemoHistoryItem(
                    content: "新しいアプリのアイデアを思いついた",
                    tags: [Tag(name: "アイデア")],
                    destination: .notionInbox
                )
                return item
            }(),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}

