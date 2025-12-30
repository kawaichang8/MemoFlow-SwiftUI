//
//  MemoFlowWidget.swift
//  MemoFlowWidget
//
//  ホーム画面ウィジェット - タップで即キャプチャ
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Timeline Provider
struct MemoFlowProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoFlowEntry {
        MemoFlowEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MemoFlowEntry) -> Void) {
        completion(MemoFlowEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoFlowEntry>) -> Void) {
        let entry = MemoFlowEntry(date: Date())
        // 1時間ごとに更新（実際は静的なので頻繁な更新は不要）
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct MemoFlowEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget Views
struct MemoFlowWidgetEntryView: View {
    var entry: MemoFlowProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView()
        case .systemMedium:
            MediumWidgetView()
        case .systemLarge:
            LargeWidgetView()
        default:
            SmallWidgetView()
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    var body: some View {
        ZStack {
            // 背景グラデーション
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(spacing: 12) {
                // アイコン
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.primary)
                
                // テキスト
                Text("メモを追加")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "memoflow://capture"))
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            HStack(spacing: 20) {
                // 左側: アイコン
                VStack(spacing: 8) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text("MemoFlow")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 区切り線
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.vertical, 16)
                
                // 右側: クイックアクション
                VStack(alignment: .leading, spacing: 12) {
                    QuickActionRow(icon: "tray.and.arrow.down", label: "Inbox")
                    QuickActionRow(icon: "checkmark.circle", label: "タスク")
                    QuickActionRow(icon: "note.text", label: "ノート")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .widgetURL(URL(string: "memoflow://capture"))
    }
}

struct QuickActionRow: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(spacing: 24) {
                // ヘッダー
                HStack {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 28, weight: .medium))
                    
                    Text("MemoFlow")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                }
                
                // メイン入力エリア（視覚的表現）
                VStack(alignment: .leading, spacing: 8) {
                    Text("何でも書いて、すぐ送る")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.tertiary)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                        .frame(height: 100)
                }
                
                // 送信先オプション
                HStack(spacing: 16) {
                    DestinationButton(icon: "tray.and.arrow.down", label: "Notion")
                    DestinationButton(icon: "checkmark.circle", label: "Todoist")
                    DestinationButton(icon: "note.text", label: "ノート")
                }
                
                Spacer()
                
                // 送信ボタン
                HStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(.systemBackground))
                            .rotationEffect(.degrees(-45))
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "memoflow://capture"))
    }
}

struct DestinationButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Widget Configuration
struct MemoFlowWidget: Widget {
    let kind: String = "MemoFlowWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoFlowProvider()) { entry in
            MemoFlowWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MemoFlow")
        .description("タップしてすばやくメモをキャプチャ")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    MemoFlowWidget()
} timeline: {
    MemoFlowEntry(date: Date())
}

#Preview("Medium", as: .systemMedium) {
    MemoFlowWidget()
} timeline: {
    MemoFlowEntry(date: Date())
}

#Preview("Large", as: .systemLarge) {
    MemoFlowWidget()
} timeline: {
    MemoFlowEntry(date: Date())
}

