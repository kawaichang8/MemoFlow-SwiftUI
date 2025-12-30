//
//  SpeechService.swift
//  MemoFlow
//
//  Apple Speechフレームワークによる音声認識サービス
//

import Foundation
import Speech
import AVFoundation

/// 音声認識の状態
enum SpeechState {
    case idle
    case requesting     // 権限リクエスト中
    case ready          // 準備完了
    case listening      // 聞き取り中
    case processing     // 処理中
    case error(Error)
}

/// 音声認識エラー
enum SpeechError: LocalizedError {
    case notAuthorized
    case notAvailable
    case audioSessionError
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "音声認識の権限がありません"
        case .notAvailable:
            return "音声認識が利用できません"
        case .audioSessionError:
            return "オーディオセッションエラー"
        case .recognitionFailed:
            return "音声認識に失敗しました"
        }
    }
}

/// 音声認識サービス
@Observable
@MainActor
final class SpeechService: NSObject {
    // MARK: - Properties
    var state: SpeechState = .idle
    var transcribedText: String = ""
    var audioLevel: Float = 0.0  // 波形表示用
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Init
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    }
    
    // MARK: - Public Methods
    
    /// 権限をリクエスト
    func requestAuthorization() async -> Bool {
        state = .requesting
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self?.state = .ready
                        continuation.resume(returning: true)
                    default:
                        self?.state = .error(SpeechError.notAuthorized)
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    /// 音声認識を開始
    func startListening() async throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }
        
        // 既存のタスクをキャンセル
        stopListening()
        
        // オーディオセッション設定
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechError.audioSessionError
        }
        
        // 認識リクエスト作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 音声レベル監視 + 認識バッファへの追加
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // 音声レベル計算
            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            
            if let data = channelData {
                var sum: Float = 0
                for i in 0..<frameLength {
                    sum += abs(data[i])
                }
                let average = sum / Float(frameLength)
                
                Task { @MainActor in
                    self?.audioLevel = min(average * 10, 1.0)
                }
            }
        }
        
        // 認識タスク開始
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopListening()
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        state = .listening
    }
    
    /// 音声認識を停止
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        audioLevel = 0.0
        
        state = .ready
    }
    
    /// テキストをリセット
    func reset() {
        transcribedText = ""
        audioLevel = 0.0
    }
    
    /// 音声認識が利用可能か
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }
    
    /// 聞き取り中か
    var isListening: Bool {
        if case .listening = state {
            return true
        }
        return false
    }
}

