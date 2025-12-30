//
//  TopBarView.swift
//  MemoFlow
//
//  上部バー: マイクボタン + 送信先セレクター
//

import SwiftUI

struct TopBarView: View {
    @Bindable var viewModel: MemoViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // マイクボタン
            VoiceInputButton(
                isListening: viewModel.isListening,
                audioLevel: viewModel.audioLevel,
                onTap: {
                    Task {
                        await viewModel.toggleVoiceInput()
                    }
                }
            )
            
            Spacer()
            
            // 送信先ピッカー
            DestinationPickerView(
                selectedDestination: Binding(
                    get: { viewModel.selectedDestination },
                    set: { viewModel.selectedDestination = $0 }
                )
            )
            
            // 設定ボタン（長押し対応）
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        showSettings = true
                        HapticManager.shared.mediumTap()
                    }
            )
        }
    }
}

// MARK: - Voice Input Button
struct VoiceInputButton: View {
    let isListening: Bool
    let audioLevel: Float
    let onTap: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景リング（音声入力中）
                if isListening {
                    Circle()
                        .stroke(
                            Color.red.opacity(0.3),
                            lineWidth: 3
                        )
                        .scaleEffect(1 + CGFloat(audioLevel) * 0.5)
                        .animation(.easeOut(duration: 0.1), value: audioLevel)
                    
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                }
                
                // マイクアイコン
                Image(systemName: isListening ? "waveform" : "mic")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isListening ? .red : .primary)
                    .symbolEffect(.variableColor, isActive: isListening)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .onChange(of: isListening) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TopBarView(
        viewModel: MemoViewModel.preview,
        showSettings: .constant(false)
    )
    .padding()
}

