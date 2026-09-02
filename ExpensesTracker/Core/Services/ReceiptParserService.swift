//
//  ReceiptParserService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/09/26.
//

import Foundation
import FoundationModels

/// Uses Apple's on-device Foundation Models framework to intelligently parse
/// raw OCR text from a receipt into a structured `ExtractedReceiptData` value.
///
/// The service is intentionally stateless — a new `LanguageModelSession` is
/// created per call so sessions are never shared between concurrent requests.
final class ReceiptParserService {
    
    static let shared = ReceiptParserService()
    private init() {}
    
    /// Parses raw OCR text and returns structured receipt data.
    ///
    /// - Parameters:
    ///   - rawText: The full string produced by `OCRService`.
    ///   - availableLabelNames: Titles of all `TransactionLabel` objects the
    ///     user has defined, so the model can suggest an exact match.
    /// - Returns: Populated `ExtractedReceiptData`, or `nil` when the
    ///   Foundation Model is unavailable or parsing fails.
    func parse(rawText: String, availableLabelNames: [String]) async -> ExtractedReceiptData? {
        
        // ── 1. Availability guard
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            print("[ReceiptParserService] Foundation Models not available on this device.")
            return nil
        }
        
        // ── 2. Build session with focused system instructions
        let labelsDescription = availableLabelNames.joined(separator: ", ")
        let instructions = """
        You are a financial receipt parsing assistant.
        Your only job is to extract structured transaction data from receipt text.
        
        Rules:
        - Extract only the FINAL grand total of the receipt (could be either "TOTAL" or "AMOUNT" labeled and pick number below it, if its blank then pick the next below).
        - Strip all currency symbols (Rp, IDR, $, €, etc.) and thousands separators from the amount.
        - The date must be in yyyy-MM-dd format. Leave null if no date is present.
        - The note should be the merchant/store name, max 60 characters.
        - transactionTypeRaw must be exactly "outflow" for purchases/expenses, or "inflow" for salary/income slips.
        - suggestedLabelName must exactly match one of these category names, or be null:
          \(labelsDescription)
        """
        
        // ── 3. Structured generation
        let prompt = """
        Parse the following receipt and return structured data:
        
        \(rawText)
        """
        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(
                to: prompt,
                generating: ExtractedReceiptData.self
            )
            return response.content
            
        } catch let error as LanguageModelSession.GenerationError {
            print("[ReceiptParserService] LanguageModelError: \(error)")
            return nil
        } catch {
            print("[ReceiptParserService] Unexpected error: \(error)")
            return nil
        }
    }
}
