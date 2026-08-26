//
//  WidgetDataWriter.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/08/26.
//

import Foundation
import WidgetKit

struct WidgetDataWriter {
    private static let appGroupID = "group.com.fidelcavell.ExpensesTracker"
    private static let widgetDataKey = "balans_widget_data"

    /// Call this after any transaction or preference change.
    ///   - Parameters:
    ///   - transactions: All transactions for the current month.
    ///   - monthlySpendingLimit: The user's set limit (from Preference).
    static func write(
        transactions: [Transaction],
        monthlySpendingLimit: Double
    ) {
        let totalIncome = transactions
            .filter { $0.type == .inflow }
            .reduce(0) { $0 + $1.amount }

        let totalExpense = transactions
            .filter { $0.type == .outflow }
            .reduce(0) { $0 + $1.amount }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: Date())

        let payload = SharedWidgetData(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            monthlySpendingLimit: monthlySpendingLimit,
            monthName: monthName,
            lastUpdated: Date()
        )

        guard
            let encoded = try? JSONEncoder().encode(payload),
            let defaults = UserDefaults(suiteName: appGroupID)
        else { return }

        defaults.set(encoded, forKey: widgetDataKey)

        print("Reload timeline widget")
        // Tell WidgetKit to reload the timeline immediately
        WidgetCenter.shared.reloadTimelines(ofKind: "BalansWidget")
    }
}

// Mirror of BalansWidget's WidgetData — must stay in sync
private struct SharedWidgetData: Codable {
    var totalIncome: Double
    var totalExpense: Double
    var monthlySpendingLimit: Double
    var monthName: String
    var lastUpdated: Date
}
