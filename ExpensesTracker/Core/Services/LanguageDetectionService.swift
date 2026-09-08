//
//  LanguageDetectionService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 08/09/26.
//

import Foundation
import NaturalLanguage

/// Detects the dominant language of a text snippet using Apple's NaturalLanguage framework.
///
/// Used to auto-select the correct `SFSpeechRecognizer` locale during live
/// transcription, improving accuracy for bilingual (Indonesian / English) users.
final class LanguageDetectionService {
    
    static let shared = LanguageDetectionService()
    private init() {}
    
    /// The set of languages this app supports for speech recognition.
    enum SupportedLanguage: String {
        case indonesian = "id-ID"
        case english    = "en-US"
    }
    
    /// Detects the dominant language of the given text.
    ///
    /// - Parameter text: The text to analyze (partial or full transcript).
    /// - Returns: The detected `SupportedLanguage`, or `nil` if detection
    ///   confidence is too low or the language is unsupported.
    func detect(from text: String) -> SupportedLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let dominant = recognizer.dominantLanguage else { return nil }
        
        switch dominant {
        case .indonesian, .malay:
            // Malay and Indonesian are closely related — treat both as Indonesian
            return .indonesian
        case .english:
            return .english
        default:
            return nil
        }
    }
    
    /// Detects language with a minimum confidence threshold.
    ///
    /// - Parameters:
    ///   - text: The text to analyze.
    ///   - minimumConfidence: Minimum confidence to accept (0.0–1.0). Default 0.5.
    /// - Returns: The detected `SupportedLanguage`, or `nil` if below threshold.
    func detect(from text: String, minimumConfidence: Double) -> SupportedLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // Get hypotheses with probabilities
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        
        // Check Indonesian / Malay first
        let idConfidence = (hypotheses[.indonesian] ?? 0) + (hypotheses[.malay] ?? 0)
        if idConfidence >= minimumConfidence {
            return .indonesian
        }
        
        // Check English
        if let enConfidence = hypotheses[.english], enConfidence >= minimumConfidence {
            return .english
        }
        
        return nil
    }
}
