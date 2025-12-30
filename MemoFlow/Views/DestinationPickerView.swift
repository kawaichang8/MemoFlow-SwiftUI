//
//  DestinationPickerView.swift
//  MemoFlow
//
//  送信先ドロップダウン - 極限ミニマル
//

import SwiftUI

struct DestinationPickerView: View {
    @Binding var selectedDestination: Destination
    @Environment(\.colorScheme) private var colorScheme
    private let settings = AppSettings.shared
    
    var body: some View {
        Menu {
            ForEach(Destination.allCases) { destination in
                Button {
                    selectedDestination = destination
                    HapticManager.shared.selection()
                } label: {
                    Label {
                        HStack {
                            Text(destination.displayName)
                            
                            if destination.requiresAPIKey && !settings.isDestinationConfigured(destination) {
                                Text("未設定")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } icon: {
                        Image(systemName: destination.iconName)
                    }
                }
                .disabled(destination.requiresAPIKey && !settings.isDestinationConfigured(destination))
            }
        } label: {
            HStack(spacing: 6) {
                // アイコン
                Image(systemName: selectedDestination.iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selectedDestination.color)
                
                // 送信先名
                Text(selectedDestination.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                
                // 矢印
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.6 : 1.0))
            )
        }
        .menuStyle(.borderlessButton)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var destination: Destination = .notionInbox
    
    VStack(spacing: 20) {
        DestinationPickerView(selectedDestination: $destination)
        
        Text("選択中: \(destination.displayName)")
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    @Previewable @State var destination: Destination = .slack
    
    VStack(spacing: 20) {
        DestinationPickerView(selectedDestination: $destination)
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
