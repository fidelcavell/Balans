//
//  TransactionViewModel.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 30/06/26.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class TransactionViewModel {
    // MARK: Dependencies
    private let context = DataProvider.shared.context
    
    // MARK: Published State
    var message: StateMessage? = nil
    
    // MARK: - Function
    /// Insert a brand-new transaction record.
    func saveTransaction(
        occurredAt: Date,
        amount: Double,
        type: TransactionType,
        note: String,
        label: TransactionLabel?
    ) {
        let newTransaction = Transaction(
            occurredAt: occurredAt,
            amount: amount,
            type: type,
            note: note
        )
        
        context.insert(newTransaction)
        
        /// To attach the relationship
        newTransaction.label = label
        
        save()
        self.message = .success("New Transaction has been added!")
    }
    
    /// Update an existing transaction record identified by its UUID.
    func updateRecord(
        id: UUID,
        occurredAt: Date,
        amount: Double,
        type: TransactionType,
        note: String,
        label: TransactionLabel?
    ) {
        let targetID = id
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.id == targetID }
        )
        
        guard let existing = try? context.fetch(descriptor).first else {
            print("[SpendingRecordVM] Record not found for update: \(id)")
            return
        }
        
        existing.occurredAt = occurredAt
        existing.amount = amount
        existing.type = type
        existing.note = note
        existing.label = label
        
        save()
        self.message = .success("The Transaction has been updated!")
    }
    
    /// Delete a single transaction record.
    func deleteRecord(_ selectedTransaction: Transaction) {
        context.delete(selectedTransaction)
        save()
        self.message = .success("The Transaction has been deleted!")
    }
    
    /// Delete a transaction record by its UUID.
    func deleteRecord(byID id: UUID) {
        let targetID = id
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.id == targetID }
        )
        
        if let selectedTransaction = try? context.fetch(descriptor).first {
            context.delete(selectedTransaction)
            save()
            self.message = .success("The Transaction has been deleted!")
        }
    }
    
    // MARK: - Internal Helpers
    private func save() {
        do {
            try context.save()
        } catch {
            self.message = .failure("Failed to perform your request. Please try again. Error: \(error.localizedDescription)")
            print("[Transaction VM] Save error: \(error.localizedDescription)")
        }
    }
}
