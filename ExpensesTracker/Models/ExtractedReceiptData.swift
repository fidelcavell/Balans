//
//  ExtractedReceiptData.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/09/26.
//

import Foundation
import FoundationModels

@Generable
struct ExtractedReceiptData {
    @Guide(description: "Final grand-total amount as a plain decimal number, no currency symbols or thousand separators. 0 if not found.")
    var amount: Double?
    
    @Guide(description: "Receipt date in yyyy-MM-dd format. Null if the receipt shows no date.")
    var dateString: String?
    
    @Guide(description: "Merchant or store name from the receipt, max 60 characters. Null if not found.")
    var note: String?
    
    @Guide(description: "Transaction direction: 'outflow' for expenses/purchases, 'inflow' for income or refunds.")
    var transactionTypeRaw: String
    
    /// The single best-matching category from the provided list.
    /// Must exactly match one of the names supplied in the prompt, or be `nil`.
    @Guide(description: "Best matching category from the available list, or null if none fits.")
    var suggestedLabelName: String?
}

// MARK: - Internal Helpers
extension ExtractedReceiptData {
    
    /// Converts the raw string into the app's `TransactionType` enum.
    var transactionType: TransactionType {
        transactionTypeRaw.lowercased() == "inflow" ? .inflow : .outflow
    }
    
    /// Parses `dateString` using a set of common receipt date formats.
    /// Falls back to `nil` so callers can default to today's date.
    var occurredAt: Date? {
        guard let dateString, !dateString.isEmpty else { return nil }
        
        let formats = ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "dd-MM-yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) { return date }
        }
        return nil
    }
    
    /// Formats `amount` as a display-friendly string without trailing zeros.
    var formattedAmount: String {
        guard let amount else { return "" }
        // Drop the decimal part if it's a whole number (e.g. 75000.0 → "75000")
        return amount.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(amount))
        : String(amount)
    }
}
