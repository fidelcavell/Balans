//
//  ReceiptParserService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/09/26.
//

import Foundation
import FoundationModels

final class ReceiptParserService {
    
    static let shared = ReceiptParserService()
    private init() {}
    
    /// Parses a `RecognizedDocument` and returns structured receipt data.
    ///
    /// - Parameters:
    ///   - document: The structured output from `OCRService`, containing full
    ///     text, individual paragraphs, and any detected table grids.
    ///   - availableLabelNames: Titles of all `TransactionLabel` objects the
    ///     user has defined, so the model can suggest an exact match.
    ///
    /// - Returns: Populated `ExtractedReceiptData`, or `nil` when the
    ///   Foundation Model is unavailable or parsing fails entirely.
    func parse(
        document: OCRService.RecognizedDocument,
        availableLabelNames: [String]
    ) async -> ExtractedReceiptData? {
        
        // ──  Availability guard
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            print("[ReceiptParserService] Foundation Models not available on this device.")
            return nil
        }
        
        // ── 2. Pre-filter: extract candidate lines that look like totals
        let candidates = extractTotalCandidates(from: document)
        
        // ──  Build focused context for the model
        let context = buildContext(document: document)
        
        print("\nCONTEXT:")
        print(context)
        
        // ──  Build session with focused system instructions
        let labelsDescription = availableLabelNames.joined(separator: ", ")
        let instructions = """
        You are a receipt parsing assistant specialising in Indonesian (Rp / IDR) \
        and English-language receipts.
        
        YOUR ONLY JOB: extract the single final amount the customer must pay.
        
        ## Amount extraction priority (highest → lowest)
        1. Grand Total / Total Keseluruhan
        2. Total Bayar / Total Pembayaran / Jumlah Bayar
        3. Tagihan / Amount Due / Balance Due
        4. Total (plain label, last occurrence)
        
        ## NEVER pick these lines as the amount
        - Subtotal / Sub Total
        - Tax / PPN / PPn / Pajak
        - Service Charge / Biaya Layanan
        - Discount / Diskon / Potongan
        - Tips / Tip
        - Any individual line-item price
        
        ## Number format rules
        - Strip all currency symbols (Rp, IDR, $, €, ¥, etc.)
        - Strip all thousands separators (periods and commas used as separators)
        - Return a plain decimal number, e.g. 75000 not Rp 75.000
        - If no valid amount found, return 0
        
        ## Other fields
        - date: yyyy-MM-dd format, null if absent
        - note: merchant or store name, max 60 characters, null if absent
        - transactionTypeRaw: "outflow" for purchases/expenses, "inflow" for income/refunds
        - suggestedLabelName: must exactly match one of [\(labelsDescription)], or null
        """
        
        let prompt = """
        ## Candidate total lines (pre-filtered — prioritise these)
        \(candidates.isEmpty ? "(none detected — use full text below)" : candidates.joined(separator: "\n"))
        
        ## Full receipt text
        \(context)
        """
        
        // ──  Structured generation
        do {
            let session = LanguageModelSession(instructions: instructions)
            
            let response = try await session.respond(
                to: prompt,
                generating: ExtractedReceiptData.self
            )
            let result = response.content
            
            // ──  Post-LLM validation: fall back to regex if model returned 0/nil
            if (result.amount ?? 0) == 0, let fallbackAmount = regexFallbackAmount(candidates: candidates) {
                print("[ReceiptParserService] Model returned 0 — using regex fallback: \(fallbackAmount)")
                return ExtractedReceiptData(
                    amount: fallbackAmount,
                    dateString: result.dateString,
                    note: result.note,
                    transactionTypeRaw: result.transactionTypeRaw,
                    suggestedLabelName: result.suggestedLabelName
                )
            }
            
            return result
            
        } catch let error as LanguageModelSession.GenerationError {
            print("[ReceiptParserService] LanguageModelError: \(error)")
            return nil
        } catch {
            print("[ReceiptParserService] Unexpected error: \(error)")
            return nil
        }
    }
    
    // MARK: - Pre-filter: total-keyword line extraction
    /// Keywords that signal a grand-total line on Indonesian and English receipts.
    /// The list is ordered from highest confidence to lowest.
    private let totalKeywords: [String] = [
        "grand total", "total keseluruhan",
        "total bayar", "total pembayaran", "jumlah bayar",
        "tagihan", "amount due", "balance due",
        "total"
    ]
    
    /// Scans every line (paragraphs + flattened table rows) for total-keyword
    /// matches and returns the matching lines, deduped and ordered by keyword
    /// confidence.
    private func extractTotalCandidates(from document: OCRService.RecognizedDocument) -> [String] {
        // Combine paragraphs with flattened table rows for the widest coverage.
        var allLines = document.paragraphs
        for table in document.tables {
            for row in table {
                let joined = row.joined(separator: "  ")
                allLines.append(joined)
            }
        }
        
        var seen = Set<String>()
        var results: [String] = []
        
        for keyword in totalKeywords {
            for line in allLines {
                let lower = line.lowercased()
                guard lower.contains(keyword), !seen.contains(line) else { continue }
                // Skip lines that are clearly NOT totals (noise-reduction guard).
                guard !isExcludedLine(lower) else { continue }
                seen.insert(line)
                results.append(line)
            }
        }
        return results
    }
    
    /// Returns `true` for lines that look like totals syntactically but should
    /// be ignored (subtotals, taxes, discounts, etc.).
    private func isExcludedLine(_ lower: String) -> Bool {
        let excluded = [
            "subtotal", "sub total", "sub-total",
            "ppn", "pajak", "tax",
            "service charge", "biaya layanan",
            "diskon", "discount", "potongan",
            "tips", "tip", "cash", "change"
        ]
        return excluded.contains { lower.contains($0) }
    }
    
    // MARK: - Context builder
    /// Builds the text block sent to the LLM: full text for context, and — if
    /// the Vision API detected tables — a formatted table section as well.
    private func buildContext(
        document: OCRService.RecognizedDocument
    ) -> String {
        var parts: [String] = [document.fullText]
        
        if !document.tables.isEmpty {
            var tableLines = ["## Detected table data (structured — highly reliable)"]
            for (tIdx, table) in document.tables.enumerated() {
                tableLines.append("Table \(tIdx + 1):")
                for row in table {
                    tableLines.append("  | " + row.joined(separator: " | ") + " |")
                }
            }
            parts.append(tableLines.joined(separator: "\n"))
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    // MARK: - Regex fallback amount picker
    /// Scans the candidate lines for the first valid positive number and returns
    /// it. This fires only when the LLM returns 0 or nil.
    private func regexFallbackAmount(candidates: [String]) -> Double? {
        // Matches numbers like 75.000, 75,000, 75000, 75000.00
        let pattern = /[\d]{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?/
        
        for line in candidates {
            
            // Try every numeric token in the line, pick the largest (most likely total).
            let matches = line.matches(of: pattern).map { match -> Double? in
                var raw = String(match.output)
                
                // Normalise: remove thousand-separator dots/commas, keep decimal dot.
                // Heuristic: if the last separator has exactly 2 digits after it,
                // treat it as a decimal point; otherwise strip it.
                if let last = raw.last, last.isNumber {
                    // Remove all dots and commas used as thousands separators.
                    raw = raw.replacingOccurrences(of: ".", with: "")
                    raw = raw.replacingOccurrences(of: ",", with: "")
                }
                return Double(raw)
            }
            if let best = matches.compactMap({ $0 }).filter({ $0 > 0 }).max() {
                return best
            }
        }
        return nil
    }
}
