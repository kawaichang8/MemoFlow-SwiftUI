//
//  StreakManager.swift
//  MemoFlow
//
//  ストリーク（連続記録）管理サービス
//  毎日のメモ送信を追跡し、モチベーションを維持
//

import Foundation
import UserNotifications

/// ストリーク管理サービス
@Observable
@MainActor
final class StreakManager {
    // MARK: - Singleton
    static let shared = StreakManager()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let currentStreak = "streak_current"
        static let longestStreak = "streak_longest"
        static let lastMemoDate = "streak_lastMemoDate"
        static let totalMemos = "streak_totalMemos"
    }
    
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    
    // MARK: - Observable Properties
    
    /// 現在のストリーク日数
    var currentStreak: Int {
        didSet {
            defaults.set(currentStreak, forKey: Keys.currentStreak)
            // 最長記録を更新
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        }
    }
    
    /// 最長ストリーク
    var longestStreak: Int {
        didSet {
            defaults.set(longestStreak, forKey: Keys.longestStreak)
        }
    }
    
    /// 最後にメモを送信した日付
    var lastMemoDate: Date? {
        didSet {
            if let date = lastMemoDate {
                defaults.set(date, forKey: Keys.lastMemoDate)
            } else {
                defaults.removeObject(forKey: Keys.lastMemoDate)
            }
        }
    }
    
    /// 総メモ数
    var totalMemos: Int {
        didSet {
            defaults.set(totalMemos, forKey: Keys.totalMemos)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 今日メモを送信済みか
    var hasSentMemoToday: Bool {
        guard let lastDate = lastMemoDate else { return false }
        return calendar.isDateInToday(lastDate)
    }
    
    /// ストリークが危険な状態か（今日まだ送信していない）
    var isStreakAtRisk: Bool {
        guard currentStreak > 0 else { return false }
        return !hasSentMemoToday
    }
    
    /// ストリークのアイコン
    var streakIcon: String {
        switch currentStreak {
        case 0:
            return "flame"
        case 1...6:
            return "flame.fill"
        case 7...29:
            return "flame.fill"
        case 30...99:
            return "star.fill"
        default:
            return "crown.fill"
        }
    }
    
    /// ストリークの色
    var streakColorName: String {
        switch currentStreak {
        case 0:
            return "gray"
        case 1...6:
            return "orange"
        case 7...29:
            return "red"
        case 30...99:
            return "purple"
        default:
            return "yellow"
        }
    }
    
    /// 表示用のストリークテキスト
    var streakDisplayText: String {
        if currentStreak == 0 {
            return "始めよう"
        }
        return "\(currentStreak)日"
    }
    
    /// モチベーションメッセージ
    var motivationMessage: String {
        if hasSentMemoToday {
            switch currentStreak {
            case 1:
                return "最初の一歩！🎉"
            case 7:
                return "1週間達成！🔥"
            case 30:
                return "1ヶ月継続！⭐️"
            case 100:
                return "100日達成！👑"
            default:
                return "今日も完了！✨"
            }
        } else if currentStreak > 0 {
            return "今日のメモを送ろう"
        } else {
            return "今日から始めよう"
        }
    }
    
    // MARK: - Init
    
    private init() {
        // UserDefaultsから読み込み
        self.currentStreak = defaults.integer(forKey: Keys.currentStreak)
        self.longestStreak = defaults.integer(forKey: Keys.longestStreak)
        self.lastMemoDate = defaults.object(forKey: Keys.lastMemoDate) as? Date
        self.totalMemos = defaults.integer(forKey: Keys.totalMemos)
        
        // アプリ起動時にストリークをチェック
        checkStreakOnLaunch()
    }
    
    // MARK: - Public Methods
    
    /// メモ送信成功時に呼び出す
    func recordMemoSent() {
        let now = Date()
        
        // 総メモ数をインクリメント
        totalMemos += 1
        
        // 今日すでに送信済みなら何もしない（ストリークは1日1回）
        if hasSentMemoToday {
            return
        }
        
        // ストリークを更新
        if let lastDate = lastMemoDate {
            if calendar.isDateInYesterday(lastDate) {
                // 昨日送信していた → ストリーク継続
                currentStreak += 1
            } else if !calendar.isDateInToday(lastDate) {
                // 昨日より前 → ストリークリセット
                currentStreak = 1
            }
        } else {
            // 初めてのメモ
            currentStreak = 1
        }
        
        lastMemoDate = now
        
        // Haptic フィードバック
        HapticManager.shared.success()
        
        print("🔥 [Streak] \(currentStreak)日目！")
    }
    
    /// アプリ起動時のストリークチェック
    func checkStreakOnLaunch() {
        guard let lastDate = lastMemoDate else { return }
        
        // 今日か昨日に送信していればストリークは維持
        if calendar.isDateInToday(lastDate) || calendar.isDateInYesterday(lastDate) {
            return
        }
        
        // それ以外はストリークリセット
        let previousStreak = currentStreak
        if previousStreak > 0 {
            currentStreak = 0
            
            // リセット通知をスケジュール（設定がオンの場合）
            if AppSettings.shared.streakEnabled {
                scheduleStreakResetNotification(previousStreak: previousStreak)
            }
        }
    }
    
    /// ストリークをリセット（デバッグ/設定用）
    func resetStreak() {
        currentStreak = 0
        lastMemoDate = nil
    }
    
    /// 全データをリセット
    func resetAllData() {
        currentStreak = 0
        longestStreak = 0
        lastMemoDate = nil
        totalMemos = 0
    }
    
    // MARK: - Notifications
    
    /// ストリークリセット通知
    private func scheduleStreakResetNotification(previousStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "ストリークがリセットされました"
        content.body = previousStreak > 1 
            ? "\(previousStreak)日のストリークでした。明日また続けよう！💪"
            : "明日また続けよう！💪"
        content.sound = .default
        
        // 即時通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_reset",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [Streak] 通知エラー: \(error)")
            }
        }
    }
    
    /// リマインダー通知をスケジュール（夜8時に今日まだ送信していない場合）
    func scheduleReminderNotification() {
        guard AppSettings.shared.streakEnabled else { return }
        guard currentStreak > 0 && !hasSentMemoToday else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 ストリークを守ろう！"
        content.body = "\(currentStreak)日続いています。今日のメモを送って継続しよう！"
        content.sound = .default
        
        // 今日の20:00にスケジュール
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [Streak] リマインダー通知エラー: \(error)")
            }
        }
    }
    
    /// 通知権限をリクエスト
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ [Streak] 通知許可")
            } else if let error = error {
                print("❌ [Streak] 通知権限エラー: \(error)")
            }
        }
    }
}

// MARK: - Widget Support
extension StreakManager {
    /// Widget用のデータを取得
    var widgetData: StreakWidgetData {
        StreakWidgetData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hasSentToday: hasSentMemoToday,
            totalMemos: totalMemos,
            icon: streakIcon,
            colorName: streakColorName
        )
    }
}

/// Widget用データ構造体
struct StreakWidgetData: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let hasSentToday: Bool
    let totalMemos: Int
    let icon: String
    let colorName: String
}

