//
//  SpeechRecognitionService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 08/09/26.
//

import Foundation
import Speech
import Observation

/// Handles live microphone → text transcription using Apple's Speech framework.
///
/// Integrates with `LanguageDetectionService` to **auto-detect** the spoken
/// language from the first few words and seamlessly restart recognition with
/// the correct locale if needed — improving accuracy for bilingual users.
///
/// Usage:
/// ```swift
/// let service = SpeechRecognitionService.shared
/// service.startListening()
/// // ... observe `transcript` for live updates
/// service.stopListening()
/// // ... read final `transcript`
/// ```
@Observable
@MainActor
final class SpeechRecognitionService {
    
    static let shared = SpeechRecognitionService()
    
    // MARK: - Published State
    /// The live-updating transcription text.
    var transcript: String = ""
    
    /// Whether the service is currently listening to the microphone.
    var isListening: Bool = false
    
    /// User-facing error message, if any.
    var errorMessage: String?
    
    /// The currently active language locale identifier (e.g. "id-ID", "en-US").
    var detectedLanguage: String = "id-ID"
    
    // MARK: - Private Properties
    
    private let languageDetector = LanguageDetectionService.shared
    
    /// Default locale — Indonesian (matches the app's Rupiah context).
    private let defaultLocale = "id-ID"
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Tracks whether we've already attempted a language switch this session
    /// to avoid infinite restart loops.
    private var hasAttemptedLanguageSwitch = false
    
    /// Minimum word count before attempting language detection.
    /// Too few words produce unreliable results.
    private let minWordsForDetection = 3
    
    /// Stores the transcript from before a language switch, so it isn't lost in the UI
    private var previousTranscript: String = ""
    
    private init() {}
    
    /// Requests permissions and begins live speech recognition.
    /// Starts with Indonesian by default and auto-switches if the spoken
    /// language is detected as English.
    func startListening() {
        // Reset state
        transcript = ""
        previousTranscript = ""
        errorMessage = nil
        detectedLanguage = defaultLocale
        hasAttemptedLanguageSwitch = false
        
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                switch status {
                case .authorized:
                    self.requestMicrophoneAndStart()
                case .denied:
                    self.errorMessage = "Speech recognition permission denied. Please enable it in Settings → Privacy → Speech Recognition."
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device."
                case .notDetermined:
                    self.errorMessage = "Speech recognition permission not yet determined."
                @unknown default:
                    self.errorMessage = "Unknown speech recognition authorization status."
                }
            }
        }
    }
    
    /// Stops the audio engine and finalizes recognition.
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    /// Resets all state for a fresh session.
    func reset() {
        stopListening()
        transcript = ""
        previousTranscript = ""
        errorMessage = nil
        detectedLanguage = defaultLocale
        hasAttemptedLanguageSwitch = false
    }
    
    // MARK: - Private Helpers
    private func requestMicrophoneAndStart() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if granted {
                    self.startRecognition(locale: self.detectedLanguage)
                } else {
                    self.errorMessage = "Microphone access denied. Please enable it in Settings → Privacy → Microphone."
                }
            }
        }
    }
    
    private func startRecognition(locale: String) {
        // Create recognizer for the requested locale
        guard let activeRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)),
              activeRecognizer.isAvailable else {
            // Fall back to the other locale
            let fallbackLocale = locale == "id-ID" ? "en-US" : "id-ID"
            if let fallback = SFSpeechRecognizer(locale: Locale(identifier: fallbackLocale)),
               fallback.isAvailable {
                startRecognitionWith(recognizer: fallback, locale: fallbackLocale)
            } else {
                errorMessage = "Speech recognition is not available on this device."
            }
            return
        }
        
        startRecognitionWith(recognizer: activeRecognizer, locale: locale)
    }
    
    private func startRecognitionWith(recognizer activeRecognizer: SFSpeechRecognizer, locale: String) {
        detectedLanguage = locale
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Use on-device recognition when available for privacy + speed
        if activeRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        let task = activeRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if let result {
                    // Append the new result to any previous transcript we saved during a language switch
                    let newText = result.bestTranscription.formattedString
                    if self.previousTranscript.isEmpty {
                        self.transcript = newText
                    } else {
                        self.transcript = self.previousTranscript + " " + newText
                    }
                    
                    // ── Auto-detect language from partial results
                    self.detectAndSwitchIfNeeded(transcript: self.transcript)
                }
                
                if let error {
                    // Ignore cancellation errors (triggered by stopListening or language switch)
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        return
                    }
                    
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.stopListening()
                }
            }
        }
        
        // ── Seamless Switching: If audio engine is already running, just swap the request and task
        if let engine = self.audioEngine, engine.isRunning {
            self.recognitionRequest?.endAudio()
            self.recognitionTask?.cancel()
            
            self.recognitionRequest = request
            self.recognitionTask = task
            return
        }
        
        // Otherwise, fresh start
        self.recognitionRequest = request
        self.recognitionTask = task
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Capture weak self to append to whichever request is CURRENTLY active
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.isListening = true
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Language Auto-Detection -> Clear to delete this code
    /// Analyzes partial transcript and restarts recognition with the correct
    /// locale if a language mismatch is detected.
    ///
    /// Only triggers once per session (after ≥3 words) to avoid disruption.
    private func detectAndSwitchIfNeeded(transcript: String) {
        // Only attempt once per session
        guard !hasAttemptedLanguageSwitch else { return }
        
        // Need enough words for reliable detection
        let wordCount = transcript.split(separator: " ").count
        guard wordCount >= minWordsForDetection else { return }
        
        // Detect with a confidence threshold
        guard let detected = languageDetector.detect(
            from: transcript,
            minimumConfidence: 0.6
        ) else { return }
        
        // Mark that we've checked (regardless of whether we switch)
        hasAttemptedLanguageSwitch = true
        
        let detectedLocale = detected.rawValue
        
        // If already using the correct locale, no action needed
        guard detectedLocale != detectedLanguage else { return }
        
        print("[SpeechRecognitionService] Language switch: \(detectedLanguage) → \(detectedLocale)")
        
        // Save the current transcript so it doesn't disappear from the UI
        self.previousTranscript = self.transcript
        
        // Seamlessly restart with detected locale (engine stays running)
        startRecognition(locale: detectedLocale)
        
        print("[SpeechRecognitionService] Seamlessly restarted with locale \(detectedLocale)")
    }
}
