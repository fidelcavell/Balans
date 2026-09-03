//
//  InsightService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/09/26.
//

import Foundation
import FoundationModels

/// A lightweight value that carries all pre-aggregated financial data
/// needed to generate AI insights — no raw `Transaction` objects are
/// passed into the model prompt.
struct InsightContext {
    let monthName: String
    let year: Int
    let totalIncome: Double
    let totalExpenses: Double
    let netSavings: Double
    let savingsRate: Double
    let topCategories: [(name: String, amount: Double, percentage: Double)]
    let yearlyIncome: Double
    let yearlyExpenses: Double
    let yearlyNetSavings: Double
}

final class InsightService {

    static let shared = InsightService()
    private init() {}

    /// Generates an `InsightReport` from the supplied `InsightContext`.
    ///
    /// - Parameter context: Pre-aggregated financial summary for the selected period.
    /// - Returns: A populated `InsightReport`, or `nil` when the Foundation
    ///   Model is unavailable or generation fails.
    func generateInsight(context: InsightContext) async -> InsightReport? {

        // ── 1. Availability guard
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            print("[InsightService] Foundation Models not available on this device.")
            return nil
        }

        // ── 2. Build focused system instructions
        let instructions = """
        You are a personal finance coach embedded in a budgeting app.
        Analyse the user's spending data and return concise, friendly, and actionable insights.

        Rules:
        - Use plain language; avoid jargon.
        - Keep each field under 120 characters.
        - Base all observations strictly on the numbers provided — do not invent data.
        - For spendingOutlook, respond with exactly one of: "Healthy", "Moderate", or "At Risk".
          Use "Healthy" when savings rate > 20%, "Moderate" when 5–20%, "At Risk" when < 5% or expenses exceed income.
        """

        // ── 3. Build a compact, readable data snapshot for the prompt
        let categoryLines = context.topCategories
            .map { "  • \($0.name): \(formatAmount($0.amount)) (\(String(format: "%.1f", $0.percentage))%)" }
            .joined(separator: "\n")

        let prompt = """
        Monthly Report — \(context.monthName) \(context.year)

        Income:    \(formatAmount(context.totalIncome))
        Expenses:  \(formatAmount(context.totalExpenses))
        Net Savings: \(formatAmount(context.netSavings)) (\(String(format: "%.1f", context.savingsRate))% savings rate)

        Top Spending Categories:
        \(categoryLines.isEmpty ? "  • No category data available" : categoryLines)

        Yearly Overview (\(context.year)):
          Total Income:   \(formatAmount(context.yearlyIncome))
          Total Expenses: \(formatAmount(context.yearlyExpenses))
          Net Savings:    \(formatAmount(context.yearlyNetSavings))

        Generate a structured InsightReport based on the data above.
        """

        // ── 4. Structured generation
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(
                to: prompt,
                generating: InsightReport.self
            )
            return response.content

        } catch let error as LanguageModelSession.GenerationError {
            print("[InsightService] LanguageModelError: \(error)")
            return nil
        } catch {
            print("[InsightService] Unexpected error: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers
    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "IDR \(formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))")"
    }
}
