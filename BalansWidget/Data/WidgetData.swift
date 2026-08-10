//
//  WidgetData.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 10/08/26.
//

import Foundation

// MARK: - App Group UserDefaults Bridge
private let appGroupID = "group.com.fidelcavell.ExpensesTracker"
private let widgetDataKey = "balans_widget_data"

// MARK: - Shared Data Model
struct WidgetData: Codable {
    var totalIncome: Double
    var totalExpense: Double
    var monthlySpendingLimit: Double
    var monthName: String
    var lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            totalIncome: 5_000_000,
            totalExpense: 2_300_000,
            monthlySpendingLimit: 4_000_000,
            monthName: "August",
            lastUpdated: .now
        )
    }

    static var empty: WidgetData {
        WidgetData(
            totalIncome: 0,
            totalExpense: 0,
            monthlySpendingLimit: 0,
            monthName: currentMonthName(),
            lastUpdated: .now
        )
    }

    static func currentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
}

func loadWidgetData() -> WidgetData {
    guard
        let defaults = UserDefaults(suiteName: appGroupID),
        let encoded = defaults.data(forKey: widgetDataKey),
        let data = try? JSONDecoder().decode(WidgetData.self, from: encoded)
    else {
        return .empty
    }
    return data
}
