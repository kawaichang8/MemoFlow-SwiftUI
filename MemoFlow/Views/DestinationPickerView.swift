//
//  DestinationPickerView.swift
//  MemoFlow
//
//  送信先ドロップダウンピッカー
//

import SwiftUI

struct DestinationPickerView: View {
    @Binding var selectedDestination: Destination
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
                                Text("（未設定）")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: destination.iconName)
                    }
                }
                .disabled(destination.requiresAPIKey && !settings.isDestinationConfigured(destination))
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedDestination.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(selectedDestination.color)
                
                Text(selectedDestination.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondaryBackground)
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
}

