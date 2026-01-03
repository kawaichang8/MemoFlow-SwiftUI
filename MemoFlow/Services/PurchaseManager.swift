//
//  PurchaseManager.swift
//  MemoFlow
//
//  RevenueCat課金管理サービス
//  Freemium + Subscription モデル
//

import Foundation
import StoreKit
// RevenueCat SDK（Package.swiftまたはSPMで追加後、以下をアンコメント）
// import RevenueCat

/// 課金プランの種類
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "memoflow_premium_monthly"
    case yearly = "memoflow_premium_yearly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .monthly: return "月額プラン"
        case .yearly: return "年額プラン"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "¥480/月"
        case .yearly: return "¥4,800/年"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "2ヶ月分お得！"
        }
    }
    
    var trialDays: Int {
        return 7 // 7日間無料トライアル
    }
}

/// プレミアム機能の種類
enum PremiumFeature: String, CaseIterable {
    case unlimitedIntegrations = "unlimited_integrations"
    case advancedAI = "advanced_ai"
    case customThemes = "custom_themes"
    case unlimitedHistory = "unlimited_history"
    case prioritySupport = "priority_support"
    
    var displayName: String {
        switch self {
        case .unlimitedIntegrations: return "無制限連携"
        case .advancedAI: return "高度AIタグ提案"
        case .customThemes: return "カスタムテーマ"
        case .unlimitedHistory: return "履歴保存無制限"
        case .prioritySupport: return "優先サポート"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedIntegrations: return "Notion、Todoist、Slack、Reflect、Emailを同時に使用"
        case .advancedAI: return "より精度の高いAIタグ提案"
        case .customThemes: return "セピア、ブルーライトカット等のテーマ"
        case .unlimitedHistory: return "送信履歴を無制限に保存"
        case .prioritySupport: return "優先的なサポート対応"
        }
    }
    
    var iconName: String {
        switch self {
        case .unlimitedIntegrations: return "link.circle.fill"
        case .advancedAI: return "brain.head.profile"
        case .customThemes: return "paintpalette.fill"
        case .unlimitedHistory: return "clock.arrow.circlepath"
        case .prioritySupport: return "star.circle.fill"
        }
    }
    
    var iconColor: String {
        switch self {
        case .unlimitedIntegrations: return "blue"
        case .advancedAI: return "purple"
        case .customThemes: return "orange"
        case .unlimitedHistory: return "green"
        case .prioritySupport: return "yellow"
        }
    }
}

/// 購入エラー
enum PurchaseError: LocalizedError {
    case notConfigured
    case productNotFound
    case purchaseFailed
    case purchaseCancelled
    case restoreFailed
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "課金システムが初期化されていません"
        case .productNotFound:
            return "商品が見つかりませんでした"
        case .purchaseFailed:
            return "購入に失敗しました。もう一度お試しください。"
        case .purchaseCancelled:
            return "購入がキャンセルされました"
        case .restoreFailed:
            return "購入の復元に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown:
            return "予期しないエラーが発生しました"
        }
    }
}

/// 課金管理マネージャー
@Observable
@MainActor
final class PurchaseManager {
    // MARK: - Singleton
    static let shared = PurchaseManager()
    
    // MARK: - Properties
    
    /// プレミアム状態
    var isPremium: Bool = false {
        didSet {
            // UserDefaultsにも保存（オフライン時のキャッシュ用）
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
    }
    
    /// 現在のサブスクリプションプラン
    var currentPlan: SubscriptionPlan?
    
    /// サブスクリプション有効期限
    var expirationDate: Date?
    
    /// 無料トライアル中か
    var isInTrialPeriod: Bool = false
    
    /// 購入処理中か
    var isPurchasing: Bool = false
    
    /// エラーメッセージ
    var errorMessage: String?
    
    /// 利用可能なパッケージ
    var availablePackages: [SubscriptionPlan] = SubscriptionPlan.allCases
    
    // MARK: - RevenueCat Configuration
    
    /// RevenueCat API Key（App Store Connect用）
    /// ⚠️ 本番環境では環境変数または設定ファイルから読み込む
    private let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY_HERE"
    
    // MARK: - Init
    
    private init() {
        // キャッシュからプレミアム状態を読み込み
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        
        // RevenueCat初期化
        configure()
    }
    
    // MARK: - Configuration
    
    /// RevenueCatの初期化
    func configure() {
        // RevenueCat SDKをPackage.swiftに追加後、以下をアンコメント
        /*
        Purchases.logLevel = .debug // デバッグ用
        Purchases.configure(withAPIKey: revenueCatAPIKey)
        
        // 購入状態の監視
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            Task { @MainActor in
                self?.handleCustomerInfo(customerInfo)
            }
        }
        */
        
        print("💰 [Purchase] PurchaseManager initialized (RevenueCat integration pending)")
    }
    
    // MARK: - Public Methods
    
    /// 購入処理
    func purchase(plan: SubscriptionPlan) async throws {
        isPurchasing = true
        errorMessage = nil
        
        defer {
            isPurchasing = false
        }
        
        // RevenueCat SDK追加後、以下をアンコメント
        /*
        do {
            guard let offerings = try await Purchases.shared.offerings().current else {
                throw PurchaseError.productNotFound
            }
            
            let packageIdentifier = plan.rawValue
            guard let package = offerings.package(identifier: packageIdentifier) else {
                throw PurchaseError.productNotFound
            }
            
            let purchaseResult = try await Purchases.shared.purchase(package: package)
            handleCustomerInfo(purchaseResult.customerInfo)
            
            HapticManager.shared.success()
            print("✅ [Purchase] 購入成功: \(plan.displayName)")
            
        } catch {
            if let purchaseError = error as? RevenueCat.ErrorCode {
                switch purchaseError {
                case .purchaseCancelledError:
                    throw PurchaseError.purchaseCancelled
                case .networkError:
                    throw PurchaseError.networkError
                default:
                    throw PurchaseError.purchaseFailed
                }
            }
            throw PurchaseError.purchaseFailed
        }
        */
        
        // デモ用: 購入成功をシミュレート
        try await Task.sleep(nanoseconds: 1_500_000_000)
        isPremium = true
        currentPlan = plan
        isInTrialPeriod = true
        expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        HapticManager.shared.success()
        print("✅ [Purchase] 購入成功（デモ）: \(plan.displayName)")
    }
    
    /// 購入の復元
    func restorePurchases() async throws {
        isPurchasing = true
        errorMessage = nil
        
        defer {
            isPurchasing = false
        }
        
        // RevenueCat SDK追加後、以下をアンコメント
        /*
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            handleCustomerInfo(customerInfo)
            
            if isPremium {
                HapticManager.shared.success()
                print("✅ [Purchase] 復元成功")
            } else {
                throw PurchaseError.restoreFailed
            }
        } catch {
            throw PurchaseError.restoreFailed
        }
        */
        
        // デモ用
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("ℹ️ [Purchase] 復元処理完了（デモ）")
    }
    
    /// プレミアム機能が使用可能かチェック
    func canUseFeature(_ feature: PremiumFeature) -> Bool {
        return isPremium
    }
    
    /// 無料版での制限チェック
    func checkFreeLimit(for feature: PremiumFeature) -> Bool {
        if isPremium { return true }
        
        // 無料版の制限
        switch feature {
        case .unlimitedIntegrations:
            // 無料版は2つまで連携可能
            return countConfiguredIntegrations() < 2
        case .advancedAI:
            // 基本AIは無料
            return true
        case .customThemes:
            // ライト/ダークのみ無料
            let theme = AppSettings.shared.appTheme
            return theme == .system || theme == .light || theme == .dark
        case .unlimitedHistory:
            // 無料版は20件まで
            return true // 履歴保存時にチェック
        case .prioritySupport:
            return false
        }
    }
    
    /// サブスクリプション管理URL
    /// RevenueCatのcustomerInfo.managementURLがあればそれを使用、なければAppleのデフォルトURL
    var managementURL: URL? {
        // RevenueCat SDK追加後、以下をアンコメント
        /*
        if let managementURL = Purchases.shared.customerInfo?.managementURL {
            return managementURL
        }
        */
        
        // フォールバック: AppleのサブスクリプションページURL
        return URL(string: "https://apps.apple.com/account/subscriptions")
    }
    
    /// サブスクリプション管理ページを開く
    func openSubscriptionManagement() {
        guard let url = managementURL else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Private Methods
    
    /// CustomerInfo処理
    private func handleCustomerInfo(_ customerInfo: Any?) {
        // RevenueCat SDK追加後、以下をアンコメント
        /*
        guard let info = customerInfo as? RevenueCat.CustomerInfo else {
            isPremium = false
            return
        }
        
        // プレミアム状態を確認
        let entitlement = info.entitlements["premium"]
        isPremium = entitlement?.isActive == true
        isInTrialPeriod = entitlement?.periodType == .trial
        expirationDate = entitlement?.expirationDate
        
        // プランを判定
        if let productIdentifier = entitlement?.productIdentifier {
            currentPlan = SubscriptionPlan(rawValue: productIdentifier)
        }
        */
    }
    
    /// 設定済み連携数をカウント
    private func countConfiguredIntegrations() -> Int {
        var count = 0
        let settings = AppSettings.shared
        
        if settings.isNotionConfigured { count += 1 }
        if settings.isTodoistConfigured { count += 1 }
        if settings.isSlackConfigured { count += 1 }
        if settings.isReflectConfigured { count += 1 }
        if settings.isEmailConfigured { count += 1 }
        
        return count
    }
}

// MARK: - Formatted Strings
extension PurchaseManager {
    /// 有効期限の表示用文字列
    var formattedExpirationDate: String? {
        guard let date = expirationDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        
        return formatter.string(from: date)
    }
    
    /// サブスクリプション状態の表示用文字列
    var subscriptionStatusText: String {
        if !isPremium {
            return "無料プラン"
        }
        
        if isInTrialPeriod {
            if let date = formattedExpirationDate {
                return "無料トライアル中（\(date)まで）"
            }
            return "無料トライアル中"
        }
        
        if let plan = currentPlan {
            return "\(plan.displayName) 利用中"
        }
        
        return "プレミアム"
    }
}

