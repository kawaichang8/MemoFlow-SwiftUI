//
//  SendButtonView.swift
//  MemoFlow
//
//  送信ボタン - スワイプ対応の大きなアクションボタン
//

import SwiftUI

struct SendButtonView: View {
    let state: SendingState
    let isEnabled: Bool
    let onSend: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    private let buttonSize: CGFloat = 72
    private let swipeThreshold: CGFloat = 50
    
    var body: some View {
        ZStack {
            // パルスリング（送信可能時）
            if isEnabled && !isSending {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 2)
                    .frame(width: buttonSize + 20, height: buttonSize + 20)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
            }
            
            // メインボタン
            Button(action: {
                HapticManager.shared.mediumTap()
                onSend()
            }) {
                ZStack {
                    // 背景
                    Circle()
                        .fill(buttonBackgroundColor)
                        .shadow(
                            color: isEnabled && !isSending ? Color.primary.opacity(0.2) : .clear,
                            radius: 12,
                            y: 6
                        )
                    
                    // アイコン
                    buttonIcon
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(buttonForegroundColor)
                        .rotationEffect(.degrees(isSending ? rotationAngle : -45))
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(SendButtonStyle())
            .disabled(!isEnabled || isSending)
            .offset(y: dragOffset)
            .gesture(swipeGesture)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
        }
        .frame(height: buttonSize + 20)
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: isSending) { _, newValue in
            if newValue {
                startLoadingAnimation()
            } else {
                rotationAngle = 0
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSending: Bool {
        if case .sending = state { return true }
        return false
    }
    
    private var buttonBackgroundColor: Color {
        if isSending {
            return Color(.systemGray4)
        }
        return isEnabled ? Color.primary : Color(.systemGray5)
    }
    
    private var buttonForegroundColor: Color {
        if isSending || !isEnabled {
            return Color(.systemGray2)
        }
        return Color(.systemBackground)
    }
    
    @ViewBuilder
    private var buttonIcon: some View {
        if isSending {
            Image(systemName: "arrow.triangle.2.circlepath")
                .symbolEffect(.rotate, options: .repeating, value: isSending)
        } else {
            Image(systemName: "paperplane.fill")
        }
    }
    
    // MARK: - Animations
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 1.5
        }
    }
    
    private func startLoadingAnimation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard isEnabled && !isSending else { return }
                // 上方向のみ
                if value.translation.height < 0 {
                    dragOffset = value.translation.height * 0.5
                }
            }
            .onEnded { value in
                guard isEnabled && !isSending else { return }
                
                if value.translation.height < -swipeThreshold {
                    // スワイプで送信
                    HapticManager.shared.mediumTap()
                    onSend()
                }
                
                dragOffset = 0
            }
    }
}

// MARK: - Send Button Style
struct SendButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        SendButtonView(
            state: .idle,
            isEnabled: true,
            onSend: {}
        )
        
        SendButtonView(
            state: .idle,
            isEnabled: false,
            onSend: {}
        )
        
        SendButtonView(
            state: .sending,
            isEnabled: true,
            onSend: {}
        )
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 40) {
        SendButtonView(
            state: .idle,
            isEnabled: true,
            onSend: {}
        )
        
        SendButtonView(
            state: .sending,
            isEnabled: true,
            onSend: {}
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}
