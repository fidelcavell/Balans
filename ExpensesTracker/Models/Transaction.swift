//
//  Transaction.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 04/07/26.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique)
    var id: UUID
    
    var occurredAt: Date        // when the spending happened
    var amount: Double           // monetary amount
    var type: TransactionType      // inflow / outflow
    var note: String            // user note / description
    var label: TransactionLabel?   // optional category link
    var createdAt: Date        // auto-timestamp on creation

    init(
        id: UUID = UUID(),
        occurredAt: Date,
        amount: Double,
        type: TransactionType,
        note: String = "-",
        label: TransactionLabel? = nil
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.amount = amount
        self.type = type
        self.note = note
        self.label = label
        self.createdAt = .now
    }
}
