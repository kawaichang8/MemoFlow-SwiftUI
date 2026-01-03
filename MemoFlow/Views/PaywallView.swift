//
//  PaywallView.swift
//  MemoFlow
//
//  プレミアムサブスクリプション Paywall画面
//  美しいミニマルデザインで自然に誘導
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseManager = PurchaseManager.shared
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    headerSection
                    
                    // プレミアム機能
                    featuresSection
                    
                    // プラン選択
                    planSelectionSection
                    
                    // 購入ボタン
                    purchaseButtonSection
                    
                    // フッター
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert(L10n.Common.error, isPresented: $showError) {
                Button(L10n.Common.ok, role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 8) {
                Text(L10n.Premium.title)
                    .font(.title.bold())
                
                Text(L10n.Premium.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "link.circle.fill",
                iconColor: .blue,
                title: L10n.Premium.Feature.unlimited,
                description: L10n.Premium.Feature.unlimitedDescription
            )
            
            FeatureRow(
                icon: "brain.head.profile",
                iconColor: .purple,
                title: L10n.Premium.Feature.ai,
                description: L10n.Premium.Feature.aiDescription
            )
            
            FeatureRow(
                icon: "paintpalette.fill",
                iconColor: .orange,
                title: L10n.Premium.Feature.themes,
                description: L10n.Premium.Feature.themesDescription
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Plan Selection Section
    private var planSelectionSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                        HapticManager.shared.lightTap()
                    }
                )
            }
        }
    }
    
    // MARK: - Purchase Button Section
    private var purchaseButtonSection: some View {
        VStack(spacing: 12) {
            // 購入ボタン
            Button {
                Task {
                    await purchase()
                }
            } label: {
                HStack {
                    if purchaseManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(L10n.Premium.trial)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(14)
            }
            .disabled(purchaseManager.isPurchasing)
            
            // トライアル説明
            Text(L10n.Premium.autoRenew(selectedPlan.price))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 復元ボタン
            Button {
                Task {
                    await restore()
                }
            } label: {
                Text(L10n.Premium.restore)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .disabled(purchaseManager.isPurchasing)
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link(L10n.Premium.terms, destination: URL(string: "https://memoflow.app/terms")!)
                Text("•")
                    .foregroundStyle(.secondary)
                Link(L10n.Premium.privacy, destination: URL(string: "https://memoflow.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Text(L10n.Premium.cancelAnytime)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func purchase() async {
        do {
            try await purchaseManager.purchase(plan: selectedPlan)
            dismiss()
        } catch let error as PurchaseError {
            if case .purchaseCancelled = error {
                // キャンセルは何もしない
                return
            }
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = L10n.Premium.Error.purchase
            showError = true
        }
    }
    
    private func restore() async {
        do {
            try await purchaseManager.restorePurchases()
            if purchaseManager.isPremium {
                dismiss()
            } else {
                errorMessage = L10n.Premium.Error.noRestore
                showError = true
            }
        } catch {
            errorMessage = L10n.Premium.Error.restoreFailed
            showError = true
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // 選択インジケーター
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.orange : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 14, height: 14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                        }
                    }
                    
                    Text(L10n.Premium.trialDays(plan.trialDays))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(plan.price)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .orange : .primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.orange : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Upsell Banner (機能制限時に表示)
struct PremiumUpsellBanner: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.orange)
                Text(L10n.Premium.features)
                    .font(.subheadline.bold())
            }
            
            Text(L10n.Premium.featureUpsell(feature.displayName))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onUpgrade) {
                Text(L10n.Premium.upgradeButton)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Compact Premium Badge (設定画面用)
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption)
            Text(L10n.Premium.badge)
                .font(.caption.bold())
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

// MARK: - Previews
#Preview("Paywall - Japanese") {
    PaywallView()
        .previewJapanese()
}

#Preview("Paywall - English") {
    PaywallView()
        .previewEnglish()
}

#Preview("Upsell Banner") {
    PremiumUpsellBanner(feature: .customThemes, onUpgrade: {})
        .padding()
}

#Preview("Premium Badge") {
    PremiumBadge()
        .padding()
}

