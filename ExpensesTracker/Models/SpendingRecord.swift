//
//  SpendingRecord.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 04/07/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Spending Flow (Income / Expense)

//enum SpendingFlow: String, Codable, CaseIterable, Identifiable {
//    case inflow   // money coming in  (salary, freelance, etc.)
//    case outflow  // money going out  (bills, food, etc.)
//
//    var id: String { rawValue }
//
//    var label: String {
//        switch self {
//        case .inflow:  return "Income"
//        case .outflow: return "Expense"
//        }
//    }
//}

// MARK: - Spending Label (Category)

//@Model
//final class SpendingLabel {
//    @Attribute(.unique)
//    var id: UUID
//
//    var title: String
//    var symbol: String       // SF Symbol name
//    var hexColor: String     // persisted as hex string
//    var isPermanent: Bool    // seeded / default labels
//
//    @Relationship(deleteRule: .nullify, inverse: \SpendingRecord.label)
//    var records: [SpendingRecord] = []
//
//    init(
//        id: UUID = UUID(),
//        title: String,
//        symbol: String,
//        tint: Color,
//        isPermanent: Bool = false
//    ) {
//        self.id = id
//        self.title = title
//        self.symbol = symbol
//        self.hexColor = tint.toHex() ?? "#FFFFFF"
//        self.isPermanent = isPermanent
//    }
//
//    // Computed – convert stored hex ↔ Color
//    var tint: Color {
//        get { Color(hex: hexColor) }
//        set { hexColor = newValue.toHex() ?? "#FFFFFF" }
//    }
//}
//
//// MARK: - Sample Labels
//
//extension SpendingLabel {
//    static var defaults: [SpendingLabel] {
//        [
//            SpendingLabel(title: "Food & Drinks",    symbol: "fork.knife",            tint: .orange,  isPermanent: true),
//            SpendingLabel(title: "Transport",        symbol: "car.fill",              tint: .blue,    isPermanent: true),
//            SpendingLabel(title: "Shopping",         symbol: "bag.fill",              tint: .purple,  isPermanent: true),
//            SpendingLabel(title: "Bills & Utilities", symbol: "doc.text.fill",        tint: .red,     isPermanent: true),
//            SpendingLabel(title: "Salary",           symbol: "banknote.fill",         tint: .green,   isPermanent: true),
//            SpendingLabel(title: "Entertainment",    symbol: "gamecontroller.fill",   tint: .pink,    isPermanent: true),
//            SpendingLabel(title: "Health",           symbol: "heart.fill",            tint: .cyan,    isPermanent: true),
//            SpendingLabel(title: "Education",        symbol: "book.fill",             tint: .indigo,  isPermanent: true),
//        ]
//    }
//}
//
//// MARK: - Spending Record (Main Transaction Model)
//
//@Model
//final class SpendingRecord {
//    @Attribute(.unique)
//    var id: UUID
//
//    var occurredAt: Date        // when the spending happened
//    var value: Double           // monetary amount
//    var flow: SpendingFlow      // inflow / outflow
//    var note: String            // user note / description
//    var label: SpendingLabel?   // optional category link
//    var recordedAt: Date        // auto-timestamp on creation
//
//    init(
//        id: UUID = UUID(),
//        occurredAt: Date,
//        value: Double,
//        flow: SpendingFlow,
//        note: String = "-",
//        label: SpendingLabel? = nil
//    ) {
//        self.id = id
//        self.occurredAt = occurredAt
//        self.value = value
//        self.flow = flow
//        self.note = note
//        self.label = label
//        self.recordedAt = .now
//    }
//}









// MARK: - Spending Record ViewModel (Full CRUD)

//@Observable
//@MainActor
//final class SpendingRecordViewModel {
//
//    // MARK: Dependencies
//    private let context: ModelContext
//
//    // MARK: Published State
//    var records: [SpendingRecord] = []
//    var labels: [SpendingLabel] = []
//
//    init(context: ModelContext) {
//        self.context = context
//    }
//
//    // ──────────────────────────────────────
//    // MARK: - Fetch
//    // ──────────────────────────────────────
//
//    /// Fetch all records sorted by date (newest first).
//    func fetchRecords() {
//        let descriptor = FetchDescriptor<SpendingRecord>(
//            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
//        )
//        do {
//            records = try context.fetch(descriptor)
//        } catch {
//            print("[SpendingRecordVM] Fetch records failed: \(error.localizedDescription)")
//        }
//    }
//
//    /// Fetch records filtered by flow type.
//    func fetchRecords(flow: SpendingFlow) {
//        let descriptor = FetchDescriptor<SpendingRecord>(
//            predicate: #Predicate { $0.flow == flow },
//            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
//        )
//        do {
//            records = try context.fetch(descriptor)
//        } catch {
//            print("[SpendingRecordVM] Fetch by flow failed: \(error.localizedDescription)")
//        }
//    }
//
//    /// Fetch records within a date range.
//    func fetchRecords(from startDate: Date, to endDate: Date) {
//        let descriptor = FetchDescriptor<SpendingRecord>(
//            predicate: #Predicate { $0.occurredAt >= startDate && $0.occurredAt <= endDate },
//            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
//        )
//        do {
//            records = try context.fetch(descriptor)
//        } catch {
//            print("[SpendingRecordVM] Fetch by date range failed: \(error.localizedDescription)")
//        }
//    }
//
//    /// Fetch all available labels.
//    func fetchLabels() {
//        let descriptor = FetchDescriptor<SpendingLabel>(
//            sortBy: [SortDescriptor(\.title)]
//        )
//        do {
//            labels = try context.fetch(descriptor)
//        } catch {
//            print("[SpendingRecordVM] Fetch labels failed: \(error.localizedDescription)")
//        }
//    }
//
//    // ──────────────────────────────────────
//    // MARK: - Save (Create)
//    // ──────────────────────────────────────
//
//    /// Insert a brand-new spending record.
//    func saveRecord(
//        occurredAt: Date,
//        value: Double,
//        flow: SpendingFlow,
//        note: String,
//        label: SpendingLabel?
//    ) {
//        // 1. Build the record without relationship
//        let record = SpendingRecord(
//            occurredAt: occurredAt,
//            value: value,
//            flow: flow,
//            note: note
//        )
//
//        // 2. Insert first so SwiftData assigns a persistent identity
//        context.insert(record)
//
//        // 3. Now safe to attach the relationship
//        record.label = label
//
//        // 4. Persist + refresh
//        persistAndRefresh()
//    }
//
//    // ──────────────────────────────────────
//    // MARK: - Update
//    // ──────────────────────────────────────
//
//    /// Update an existing record identified by its UUID.
//    func updateRecord(
//        id: UUID,
//        occurredAt: Date,
//        value: Double,
//        flow: SpendingFlow,
//        note: String,
//        label: SpendingLabel?
//    ) {
//        let targetID = id
//        let descriptor = FetchDescriptor<SpendingRecord>(
//            predicate: #Predicate { $0.id == targetID }
//        )
//
//        guard let existing = try? context.fetch(descriptor).first else {
//            print("[SpendingRecordVM] Record not found for update: \(id)")
//            return
//        }
//
//        existing.occurredAt = occurredAt
//        existing.value = value
//        existing.flow = flow
//        existing.note = note
//        existing.label = label
//
//        persistAndRefresh()
//    }
//
//    // ──────────────────────────────────────
//    // MARK: - Delete
//    // ──────────────────────────────────────
//
//    /// Delete a single record.
//    func deleteRecord(_ record: SpendingRecord) {
//        context.delete(record)
//        persistAndRefresh()
//    }
//
//    /// Delete a record by its UUID.
//    func deleteRecord(byID id: UUID) {
//        let targetID = id
//        let descriptor = FetchDescriptor<SpendingRecord>(
//            predicate: #Predicate { $0.id == targetID }
//        )
//
//        if let record = try? context.fetch(descriptor).first {
//            context.delete(record)
//            persistAndRefresh()
//        }
//    }
//
//    // ──────────────────────────────────────
//    // MARK: - Internal Helpers
//    // ──────────────────────────────────────
//
//    private func persistAndRefresh() {
//        do {
//            try context.save()
//        } catch {
//            print("[SpendingRecordVM] Save error: \(error.localizedDescription)")
//        }
//        fetchRecords()
//    }
//}
