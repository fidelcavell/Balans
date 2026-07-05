//
//  TransactionLabel.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 04/07/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TransactionLabel {
    @Attribute(.unique)
    var id: UUID
    
    var title: String
    var symbol: String       // SF Symbol name
    var hexColor: String     // persisted as hex string
    var isPermanent: Bool    // seeded / default labels
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.label)
    var transactions: [Transaction] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        symbol: String,
        tint: Color,
        isPermanent: Bool = false
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.hexColor = tint.toHex() ?? "#FFFFFF"
        self.isPermanent = isPermanent
    }
    
    // Computed – convert stored hex ↔ Color
    var tint: Color {
        get { Color(hex: hexColor) }
        set { hexColor = newValue.toHex() ?? "#FFFFFF" }
    }
}

extension TransactionLabel {
    static var defaults: [TransactionLabel] {
        [
            TransactionLabel(title: "Food & Drinks", symbol: "fork.knife", tint: .orange, isPermanent: true),
            TransactionLabel(title: "Transport", symbol: "car.fill", tint: .blue, isPermanent: true),
            TransactionLabel(title: "Shopping", symbol: "bag.fill", tint: .purple, isPermanent: true),
            TransactionLabel(title: "Bills & Utilities", symbol: "doc.text.fill", tint: .red, isPermanent: true),
            TransactionLabel(title: "Salary", symbol: "banknote.fill", tint: .green, isPermanent: true),
            TransactionLabel(title: "Entertainment", symbol: "gamecontroller.fill", tint: .pink, isPermanent: true),
            TransactionLabel(title: "Health", symbol: "heart.fill", tint: .cyan, isPermanent: true),
            TransactionLabel(title: "Education", symbol: "book.fill", tint: .indigo, isPermanent: true),
        ]
    }
}
