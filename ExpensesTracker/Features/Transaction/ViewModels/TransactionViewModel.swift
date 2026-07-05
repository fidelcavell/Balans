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
    var transactions: [Transaction] = []
    var labels: [TransactionLabel] = []
    
    // MARK: - Function
    /// Fetch all records sorted by date (newest first).
    func fetchTransactions() {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        do {
            transactions = try context.fetch(descriptor)
        } catch {
            print("[Transaction VM] Fetch records failed: \(error.localizedDescription)")
        }
    }
    
    /// Fetch transactions filtered by type.
    func fetchTransactions(type: TransactionType) {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.type == type },
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        do {
            transactions = try context.fetch(descriptor)
        } catch {
            print("[Transaction VM] Fetch by type failed: \(error.localizedDescription)")
        }
    }
    
    /// Fetch transactions within a date range.
    func fetchTransactions(from startDate: Date, to endDate: Date) {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.occurredAt >= startDate && $0.occurredAt <= endDate },
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        do {
            transactions = try context.fetch(descriptor)
        } catch {
            print("[Transaction VM] Fetch by date range failed: \(error.localizedDescription)")
        }
    }
    
    /// Fetch all available labels.
    func fetchLabels() {
        let descriptor = FetchDescriptor<TransactionLabel>(
            sortBy: [SortDescriptor(\.title)]
        )
        do {
            labels = try context.fetch(descriptor)
        } catch {
            print("[Transaction VM] Fetch labels failed: \(error.localizedDescription)")
        }
    }
    
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
        
        saveAndRefresh()
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
        
        saveAndRefresh()
    }
    
    /// Delete a single transaction record.
    func deleteRecord(_ selectedTransaction: Transaction) {
        context.delete(selectedTransaction)
        saveAndRefresh()
    }
    
    /// Delete a transaction record by its UUID.
    func deleteRecord(byID id: UUID) {
        let targetID = id
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.id == targetID }
        )
        
        if let selectedTransaction = try? context.fetch(descriptor).first {
            context.delete(selectedTransaction)
            saveAndRefresh()
        }
    }
    
    // MARK: - Internal Helpers
    private func saveAndRefresh() {
        do {
            try context.save()
        } catch {
            print("[Transaction VM] Save error: \(error.localizedDescription)")
        }
        fetchTransactions()
    }
}
