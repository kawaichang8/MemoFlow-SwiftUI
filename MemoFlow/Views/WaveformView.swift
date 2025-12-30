//
//  WaveformView.swift
//  MemoFlow
//
//  音声入力時の波形アニメーション
//

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    
    @State private var phase: CGFloat = 0
    
    private let barCount: Int = 40
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let barWidth: CGFloat = 3
                let barCountCG = CGFloat(barCount)
                let spacing: CGFloat = (size.width - barCountCG * barWidth) / (barCountCG - 1)
                let maxHeight: CGFloat = size.height * 0.8
                let minHeight: CGFloat = 4
                
                let time: Double = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<barCount {
                    let iCG = CGFloat(i)
                    let x: CGFloat = iCG * (barWidth + spacing)
                    
                    // 波形の高さ計算（Doubleで計算）
                    let normalizedPosition: Double = Double(i) / Double(barCount - 1)
                    let waveInput: Double = normalizedPosition * Double.pi * 3.0 + time * 4.0
                    let wave: Double = sin(waveInput)
                    let levelInfluence: CGFloat = CGFloat(audioLevel) * 0.8 + 0.2
                    let waveContribution: CGFloat = CGFloat(0.3 + wave * 0.3)
                    let height: CGFloat = max(minHeight, maxHeight * waveContribution * levelInfluence)
                    
                    let y: CGFloat = (size.height - height) / 2
                    
                    let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                    let path = RoundedRectangle(cornerRadius: barWidth / 2)
                        .path(in: rect)
                    
                    // グラデーション的な色
                    let opacity: Double = 0.4 + normalizedPosition * 0.4
                    context.fill(path, with: .color(.primary.opacity(opacity)))
                }
            }
        }
    }
}

// MARK: - Simple Waveform (Alternative)
struct SimpleWaveformView: View {
    let audioLevel: Float
    
    private let barCount: Int = 5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    audioLevel: audioLevel,
                    delay: Double(index) * 0.1
                )
            }
        }
    }
}

struct WaveformBar: View {
    let audioLevel: Float
    let delay: Double
    
    @State private var animating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.red.opacity(0.8))
            .frame(width: 4)
            .frame(height: animating ? 30 + CGFloat(audioLevel) * 20 : 8)
            .animation(
                .easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        WaveformView(audioLevel: 0.5)
            .frame(height: 60)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        
        SimpleWaveformView(audioLevel: 0.7)
            .frame(height: 40)
    }
    .padding()
}

#Preview("Dark") {
    WaveformView(audioLevel: 0.8)
        .frame(height: 60)
        .padding()
        .preferredColorScheme(.dark)
}
