//
//  Color+Extensions.swift
//  MemoFlow
//
//  ダークモード対応のカラー定義
//

import SwiftUI

extension Color {
    // MARK: - 背景色
    
    /// メイン背景（ライト: 白、ダーク: 黒に近いグレー）
    static let appBackground = Color(.systemBackground)
    
    /// セカンダリ背景（ライト: 薄いグレー、ダーク: 少し明るいグレー）
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    /// グループ背景
    static let groupedBackground = Color(.systemGroupedBackground)
    
    // MARK: - テキスト色
    
    /// プライマリテキスト
    static let textPrimary = Color(.label)
    
    /// セカンダリテキスト
    static let textSecondary = Color(.secondaryLabel)
    
    /// ターシャリテキスト
    static let textTertiary = Color(.tertiaryLabel)
    
    // MARK: - ボタン・アクセント
    
    /// 送信ボタン背景（ライト: 黒、ダーク: 白）
    static let sendButtonBackground = Color.primary
    
    /// 送信ボタンアイコン（ライト: 白、ダーク: 黒）
    static let sendButtonIcon = Color(.systemBackground)
    
    // MARK: - タグチップ
    
    /// 採用済みタグ背景
    static let adoptedTagBackground = Color.orange
    
    /// 採用済みタグテキスト
    static let adoptedTagText = Color.white
    
    /// 提案タグ背景
    static let suggestedTagBackground = Color(.systemGray6)
    
    /// 提案タグ枠線
    static let suggestedTagBorder = Color(.systemGray4)
    
    /// 提案タグテキスト
    static let suggestedTagText = Color(.secondaryLabel)
    
    // MARK: - セパレーター・ボーダー
    
    /// セパレーター
    static let separator = Color(.separator)
    
    /// 薄いボーダー
    static let lightBorder = Color(.systemGray5)
    
    // MARK: - ステータス
    
    /// 成功（緑）
    static let success = Color.green
    
    /// エラー（赤）
    static let error = Color.red
    
    /// 警告（オレンジ）
    static let warning = Color.orange
    
    // MARK: - 波形・アニメーション
    
    /// 波形バーの色
    static let waveformBar = Color.primary.opacity(0.6)
}

// MARK: - UIColor Extension for Dynamic Colors
extension UIColor {
    /// ライト/ダークで異なる色を返す
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            case .light, .unspecified:
                return light
            @unknown default:
                return light
            }
        }
    }
}

