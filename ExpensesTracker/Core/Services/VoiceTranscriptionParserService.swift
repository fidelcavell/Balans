//
//  VoiceTransactionParserService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 08/09/26.
//

import Foundation
import FoundationModels

/// This is the speech counterpart to `ReceiptParserService` — optimized for
/// natural-language spoken inputs rather than OCR text.
final class VoiceTranscriptionParserService {
    
    static let shared = VoiceTranscriptionParserService()
    private init() {}
    
    /// Parses a spoken transcript into structured transaction data.
    ///
    /// - Parameters:
    ///   - transcript: The raw text from `SpeechRecognitionService`.
    ///   - availableLabelNames: Titles of all `TransactionLabel` objects,
    ///     so the model can suggest an exact match.
    ///   - referenceDate: The current date, used to resolve relative
    ///     expressions like "yesterday" or "last Friday".
    ///
    /// - Returns: Populated `ExtractedReceiptData`, or `nil` when the
    ///   Foundation Model is unavailable or parsing fails.
    func parse(
        transcript: String,
        availableLabelNames: [String],
        referenceDate: Date = .now
    ) async -> ExtractedReceiptData? {
        
        // ── Availability guard
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            print("[VoiceTransactionParserService] Foundation Models not available on this device.")
            return nil
        }
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("[VoiceTransactionParserService] Empty transcript — skipping.")
            return nil
        }
        
        // ── Format reference date for the prompt
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let todayString = formatter.string(from: referenceDate)
        
        // Also provide day-of-week for relative date resolution
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        weekdayFormatter.locale = Locale(identifier: "en_US")
        let dayOfWeek = weekdayFormatter.string(from: referenceDate)
        
        // ── Build instructions
        let labelsDescription = availableLabelNames.joined(separator: ", ")
        let instructions = """
        You are a transaction data extractor. The user will speak a sentence describing a financial transaction in Indonesian or English.
        
        YOUR ONLY JOB: Extract structured transaction data from the spoken text. Output strictly as the required JSON schema.
        
        ## Today's Context
        - Today's date: \(todayString) (\(dayOfWeek))
        - Use this to resolve relative dates like "kemarin" (yesterday), "minggu lalu" (last week), "2 hari lalu" (2 days ago), "tadi" (earlier today), "besok" (tomorrow), etc.
        
        ## Amount Extraction Rules
        1. Parse Indonesian casual amounts:
           - "ribu" = thousand (×1,000) → "45 ribu" = 45000, "2.5 ribu" = 2500
           - "juta" = million (×1,000,000) → "1.5 juta" = 1500000
           - "ratus" = hundred (×100) → "3 ratus ribu" = 300000
           - Direct numbers: "50000" = 50000
        2. Parse English casual amounts:
           - "k" or "thousand" = ×1,000 → "45k" = 45000
           - "million" or "mil" = ×1,000,000
        3. Return a plain numeric value (e.g., 45000). Return 0 if no amount found.
        
        ## Transaction Type Rules
        - Default to "outflow" (expense) unless the text clearly indicates income.
        - Income keywords: "gaji" (salary), "terima" (receive), "dapat" (got), "income", "salary", "received", "earned", "refund"
        - Expense keywords: "beli" (buy), "bayar" (pay), "makan" (eat), "spent", "bought", "paid"
        
        ## Note Extraction
        - Extract a brief description of what the transaction was about.
        - Max 100 characters.
        
        ## Label Matching
        - Available labels: [\(labelsDescription)]
        - Match the transaction to the most fitting label from the list above.
        - Must be an exact match from the list, or null if unsure.
        
        ## JSON Output Schema
        {
          "amount": (Number) The parsed amount.
          "dateString": (String or null) Format "yyyy-MM-dd". Use today's date context to resolve relative dates.
          "note": (String or null) Brief description. Max 60 chars.
          "transactionTypeRaw": (String) "outflow" or "inflow".
          "suggestedLabelName": (String or null) Must exactly match one of the available labels.
        }
        """
        
        // ── Structured generation
        do {
            let session = LanguageModelSession(instructions: instructions)
            
            let options = GenerationOptions(
                sampling: .greedy,
                temperature: 0
            )
            
            let response = try await session.respond(
                to: transcript,
                generating: ExtractedReceiptData.self,
                options: options
            )
            
            let result = response.content
            
            print("[VoiceTransactionParserService] Parsed result: \(result)")
            return result
            
        } catch let error as LanguageModelSession.GenerationError {
            print("[VoiceTransactionParserService] GenerationError: \(error)")
            return nil
        } catch {
            print("[VoiceTransactionParserService] Unexpected error: \(error)")
            return nil
        }
    }
}
