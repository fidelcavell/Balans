//
//  InsightViewModel.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/09/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class InsightViewModel {

    /// The latest AI-generated report. `nil` before the first successful generation.
    var report: InsightReport? = nil

    /// `true` while waiting for the model to respond.
    var isLoading: Bool = false

    /// Set when the model is unavailable on this device.
    var isUnavailable: Bool = false

    /// Surfaced to `InsightView` for user-facing error handling.
    var message: StateMessage? = nil

    private let service: InsightService

    init(service: InsightService = .shared) {
        self.service = service
    }

    /// Generates a fresh `InsightReport` from the already-computed view data.
    ///
    /// - Parameters:
    ///   - currentMonth: The `MonthlyTransaction` for the selected month.
    ///   - yearlyTrendData: All `MonthlyTransaction` records for the selected year.
    ///   - selectedYear: The four-digit year currently in view.
    func generateInsight(
        currentMonth: MonthlyTransaction?,
        yearlyTrendData: [MonthlyTransaction],
        selectedYear: Int
    ) async {
        guard !isLoading else { return }

        isLoading = true
        report = nil
        isUnavailable = false

        let context = buildContext(
            currentMonth: currentMonth,
            yearlyTrendData: yearlyTrendData,
            selectedYear: selectedYear
        )

        let result = await service.generateInsight(context: context)

        isLoading = false

        if let result {
            report = result
        } else {
            isUnavailable = true
            message = .failure("AI insights are unavailable on this device.")
        }
    }

    // MARK: - Private Helpers
    private func buildContext(
        currentMonth: MonthlyTransaction?,
        yearlyTrendData: [MonthlyTransaction],
        selectedYear: Int
    ) -> InsightContext {
        let income   = currentMonth?.totalIncome   ?? 0
        let expenses = currentMonth?.totalExpenses ?? 0
        let net      = income - expenses
        let rate     = income > 0 ? max(0, net / income * 100) : 0

        let totalMonthExpenses = currentMonth?.labels.reduce(0) { $0 + $1.amount } ?? 0

        let topCategories: [(name: String, amount: Double, percentage: Double)] = (currentMonth?.labels ?? [])
            .prefix(5)
            .map { label in
                let pct = totalMonthExpenses > 0 ? (label.amount / totalMonthExpenses) * 100 : 0
                return (name: label.label.title, amount: label.amount, percentage: pct)
            }

        let yearlyIncome   = yearlyTrendData.reduce(0) { $0 + $1.totalIncome }
        let yearlyExpenses = yearlyTrendData.reduce(0) { $0 + $1.totalExpenses }

        return InsightContext(
            monthName:       currentMonth?.monthName ?? "—",
            year:            selectedYear,
            totalIncome:     income,
            totalExpenses:   expenses,
            netSavings:      net,
            savingsRate:     rate,
            topCategories:   topCategories,
            yearlyIncome:    yearlyIncome,
            yearlyExpenses:  yearlyExpenses,
            yearlyNetSavings: yearlyIncome - yearlyExpenses
        )
    }
}
