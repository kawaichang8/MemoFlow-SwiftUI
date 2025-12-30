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
        MemoFlowEntry(date: Date(), streakData: StreakWidgetData.placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MemoFlowEntry) -> Void) {
        let streakData = loadStreakData()
        completion(MemoFlowEntry(date: Date(), streakData: streakData))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoFlowEntry>) -> Void) {
        let streakData = loadStreakData()
        let entry = MemoFlowEntry(date: Date(), streakData: streakData)
        // 15分ごとに更新（ストリーク表示のため）
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    /// ストリークデータを読み込み（App Group共有UserDefaults）
    private func loadStreakData() -> StreakWidgetData {
        // App Groupを使う場合: UserDefaults(suiteName: "group.com.yourapp.memoflow")
        let defaults = UserDefaults.standard
        
        let currentStreak = defaults.integer(forKey: "streak_current")
        let longestStreak = defaults.integer(forKey: "streak_longest")
        let totalMemos = defaults.integer(forKey: "streak_totalMemos")
        let lastMemoDate = defaults.object(forKey: "streak_lastMemoDate") as? Date
        
        let hasSentToday: Bool
        if let lastDate = lastMemoDate {
            hasSentToday = Calendar.current.isDateInToday(lastDate)
        } else {
            hasSentToday = false
        }
        
        return StreakWidgetData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hasSentToday: hasSentToday,
            totalMemos: totalMemos,
            icon: streakIcon(for: currentStreak),
            colorName: streakColorName(for: currentStreak)
        )
    }
    
    private func streakIcon(for streak: Int) -> String {
        switch streak {
        case 0: return "flame"
        case 1...6: return "flame.fill"
        case 7...29: return "flame.fill"
        case 30...99: return "star.fill"
        default: return "crown.fill"
        }
    }
    
    private func streakColorName(for streak: Int) -> String {
        switch streak {
        case 0: return "gray"
        case 1...6: return "orange"
        case 7...29: return "red"
        case 30...99: return "purple"
        default: return "yellow"
        }
    }
}

// MARK: - Widget Entry
struct MemoFlowEntry: TimelineEntry {
    let date: Date
    let streakData: StreakWidgetData
}

// MARK: - Streak Widget Data
struct StreakWidgetData {
    let currentStreak: Int
    let longestStreak: Int
    let hasSentToday: Bool
    let totalMemos: Int
    let icon: String
    let colorName: String
    
    static let placeholder = StreakWidgetData(
        currentStreak: 7,
        longestStreak: 14,
        hasSentToday: true,
        totalMemos: 42,
        icon: "flame.fill",
        colorName: "orange"
    )
    
    var color: Color {
        switch colorName {
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Widget Views
struct MemoFlowWidgetEntryView: View {
    var entry: MemoFlowProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(streakData: entry.streakData)
        case .systemMedium:
            MediumWidgetView(streakData: entry.streakData)
        case .systemLarge:
            LargeWidgetView(streakData: entry.streakData)
        default:
            SmallWidgetView(streakData: entry.streakData)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let streakData: StreakWidgetData
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(spacing: 8) {
                // ストリークバッジ
                HStack(spacing: 4) {
                    Image(systemName: streakData.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(streakData.color)
                    
                    Text(streakData.currentStreak > 0 ? "\(streakData.currentStreak)日" : "")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(streakData.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(streakData.color.opacity(0.15))
                )
                
                // アイコン
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.primary)
                
                // テキスト
                Text(streakData.hasSentToday ? "今日完了 ✓" : "メモを追加")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(streakData.hasSentToday ? .green : .secondary)
            }
        }
        .widgetURL(URL(string: "memoflow://capture"))
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let streakData: StreakWidgetData
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            HStack(spacing: 16) {
                // 左側: ストリーク情報
                VStack(spacing: 12) {
                    // ストリークバッジ（大）
                    ZStack {
                        Circle()
                            .fill(streakData.color.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Image(systemName: streakData.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(streakData.color)
                            
                            Text("\(streakData.currentStreak)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(streakData.color)
                        }
                    }
                    
                    Text(streakData.hasSentToday ? "今日完了!" : "継続中")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(streakData.hasSentToday ? .green : .secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 区切り線
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.vertical, 12)
                
                // 右側: 統計とアクション
                VStack(alignment: .leading, spacing: 10) {
                    // 統計
                    HStack(spacing: 16) {
                        StatMini(label: "最長", value: "\(streakData.longestStreak)日", icon: "trophy.fill", color: .yellow)
                        StatMini(label: "総数", value: "\(streakData.totalMemos)", icon: "note.text", color: .blue)
                    }
                    
                    // キャプチャボタン
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                        Text("メモを追加")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .widgetURL(URL(string: "memoflow://capture"))
    }
}

// MARK: - Stat Mini (for Medium Widget)
struct StatMini: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Large Widget
struct LargeWidgetView: View {
    let streakData: StreakWidgetData
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(spacing: 20) {
                // ヘッダー（ストリーク付き）
                HStack {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 24, weight: .medium))
                    
                    Text("MemoFlow")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    // ストリークバッジ
                    HStack(spacing: 4) {
                        Image(systemName: streakData.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(streakData.color)
                        
                        Text("\(streakData.currentStreak)日")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(streakData.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(streakData.color.opacity(0.15))
                    )
                }
                
                // ストリーク統計
                HStack(spacing: 12) {
                    StreakStatCard(
                        icon: streakData.icon,
                        value: "\(streakData.currentStreak)",
                        label: "現在",
                        color: streakData.color
                    )
                    StreakStatCard(
                        icon: "trophy.fill",
                        value: "\(streakData.longestStreak)",
                        label: "最長",
                        color: .yellow
                    )
                    StreakStatCard(
                        icon: "note.text",
                        value: "\(streakData.totalMemos)",
                        label: "総数",
                        color: .blue
                    )
                }
                
                // 今日の状態
                HStack {
                    Image(systemName: streakData.hasSentToday ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(streakData.hasSentToday ? .green : .secondary)
                    Text(streakData.hasSentToday ? "今日のメモ完了！" : "今日はまだ送信していません")
                        .font(.system(size: 13))
                        .foregroundStyle(streakData.hasSentToday ? .primary : .secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                )
                
                Spacer()
                
                // 送信ボタン
                HStack {
                    Spacer()
                    
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color(.systemBackground))
                                .rotationEffect(.degrees(-45))
                        }
                        
                        Text("タップしてキャプチャ")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "memoflow://capture"))
    }
}

// MARK: - Streak Stat Card (for Large Widget)
struct StreakStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
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

