//
//  SendButtonView.swift
//  MemoFlow
//
//  送信ボタン - 「流してスッキリ」の紙飛行機アイコン
//

import SwiftUI

struct SendButtonView: View {
    let state: SendingState
    let isEnabled: Bool
    let onSend: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var flyAwayOffset: CGFloat = 0
    @State private var flyAwayOpacity: Double = 1.0
    
    private let buttonSize: CGFloat = 80
    private let swipeThreshold: CGFloat = 60
    
    var body: some View {
        ZStack {
            // パルスリング
            if isEnabled && !isSending {
                Circle()
                    .stroke(buttonColor.opacity(0.12), lineWidth: 2)
                    .frame(width: buttonSize + 28, height: buttonSize + 28)
                    .scaleEffect(pulseScale)
                    .opacity(Double(2.0 - pulseScale))
                
                Circle()
                    .stroke(buttonColor.opacity(0.08), lineWidth: 1.5)
                    .frame(width: buttonSize + 48, height: buttonSize + 48)
                    .scaleEffect(pulseScale * 0.9)
                    .opacity(Double(2.0 - pulseScale) * 0.5)
            }
            
            // メインボタン
            Button(action: {
                guard isEnabled && !isSending else { return }
                HapticManager.shared.mediumTap()
                triggerFlyAnimation()
                onSend()
            }) {
                ZStack {
                    // 背景円
                    Circle()
                        .fill(buttonBackgroundColor)
                        .shadow(
                            color: isEnabled && !isSending ? buttonColor.opacity(0.3) : .clear,
                            radius: 20,
                            y: 10
                        )
                    
                    // 紙飛行機アイコン
                    buttonIcon
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(buttonForegroundColor)
                        .rotationEffect(.degrees(isSending ? iconRotation : -45))
                        .offset(
                            x: isSending ? 0 : 2 + flyAwayOffset * 0.3,
                            y: isSending ? 0 : -2 - flyAwayOffset
                        )
                        .opacity(flyAwayOpacity)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(SendButtonStyle())
            .disabled(!isEnabled || isSending)
            .offset(y: dragOffset)
            .gesture(swipeGesture)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: dragOffset)
        }
        .frame(height: buttonSize + 52)
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: isSending) { _, newValue in
            if newValue {
                startLoadingAnimation()
            } else {
                resetAnimations()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isSending: Bool {
        if case .sending = state { return true }
        return false
    }
    
    private var buttonColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var buttonBackgroundColor: Color {
        if isSending {
            return Color(.systemGray5)
        }
        return isEnabled ? buttonColor : Color(.systemGray5)
    }
    
    private var buttonForegroundColor: Color {
        if isSending {
            return Color(.systemGray3)
        }
        if !isEnabled {
            return Color(.systemGray3)
        }
        return colorScheme == .dark ? .black : .white
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
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
            pulseScale = 1.7
        }
    }
    
    private func startLoadingAnimation() {
        withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
            iconRotation = 360
        }
    }
    
    private func triggerFlyAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            flyAwayOffset = 50
            flyAwayOpacity = 0.0
        }
    }
    
    private func resetAnimations() {
        iconRotation = 0
        flyAwayOffset = 0
        flyAwayOpacity = 1.0
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard isEnabled && !isSending else { return }
                if value.translation.height < 0 {
                    dragOffset = value.translation.height * 0.35
                    
                    if value.translation.height < -swipeThreshold * 0.6 {
                        HapticManager.shared.lightTap()
                    }
                }
            }
            .onEnded { value in
                guard isEnabled && !isSending else { return }
                
                if value.translation.height < -swipeThreshold {
                    HapticManager.shared.mediumTap()
                    triggerFlyAnimation()
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
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 50) {
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
    .background(Color.appBackground.ignoresSafeArea())
}

#Preview("Dark Mode") {
    VStack(spacing: 50) {
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
    .background(Color.appBackground.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
