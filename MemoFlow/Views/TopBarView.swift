//
//  TopBarView.swift
//  MemoFlow
//
//  上部バー - 極限ミニマル: マイク + 送信先のみ
//

import SwiftUI

struct TopBarView: View {
    @Bindable var viewModel: MemoViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // マイクボタン（左）
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
            
            // 送信先ピッカー（右）
            DestinationPickerView(
                selectedDestination: Binding(
                    get: { viewModel.selectedDestination },
                    set: { viewModel.selectedDestination = $0 }
                )
            )
        }
        .frame(height: 44)
    }
}

// MARK: - Voice Input Button
struct VoiceInputButton: View {
    let isListening: Bool
    let audioLevel: Float
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false
    
    private var buttonSize: CGFloat { 44 }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景リング（音声入力中）
                if isListening {
                    // 音量レベルリング
                    Circle()
                        .stroke(
                            Color.red.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: buttonSize + 8, height: buttonSize + 8)
                        .scaleEffect(1 + CGFloat(audioLevel) * 0.4)
                    
                    // パルスリング
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                }
                
                // 背景円（非録音時）
                if !isListening {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: buttonSize, height: buttonSize)
                }
                
                // マイクアイコン
                Image(systemName: isListening ? "waveform" : "mic.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isListening ? .red : .primary)
                    .symbolEffect(.variableColor, isActive: isListening)
            }
            .frame(width: buttonSize + 10, height: buttonSize + 10)
            .animation(.easeOut(duration: 0.08), value: audioLevel)
        }
        .buttonStyle(.plain)
        .onChange(of: isListening) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
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
    VStack {
        TopBarView(
            viewModel: MemoViewModel.preview,
            showSettings: .constant(false)
        )
        .padding()
        
        Spacer()
    }
    .background(Color.appBackground)
}

#Preview("Listening") {
    VStack {
        HStack {
            VoiceInputButton(
                isListening: true,
                audioLevel: 0.5,
                onTap: {}
            )
            
            Spacer()
        }
        .padding()
        
        Spacer()
    }
    .background(Color.appBackground)
}

#Preview("Dark Mode") {
    VStack {
        TopBarView(
            viewModel: MemoViewModel.preview,
            showSettings: .constant(false)
        )
        .padding()
        
        Spacer()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
