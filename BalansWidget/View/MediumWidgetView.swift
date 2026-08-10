//
//  MediumWidgetView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 10/08/26.
//

import SwiftUI

struct MediumWidgetView: View {
    let data: WidgetData

    private var balance: Double { data.totalIncome - data.totalExpense }
    private var isPositive: Bool { balance >= 0 }
    private var totalVolume: Double { data.totalIncome + data.totalExpense }

    private var incomeRatio: Double {
        guard totalVolume > 0 else { return 0 }
        return data.totalIncome / totalVolume
    }

    private var expenseRatio: Double {
        guard totalVolume > 0 else { return 0 }
        return data.totalExpense / totalVolume
    }

    private var spendingRatio: Double {
        guard data.monthlySpendingLimit > 0 else { return 0 }
        return min(data.totalExpense / data.monthlySpendingLimit, 1.0)
    }

    var body: some View {
        HStack(spacing: 0) {
            // MARK: Left Panel - Balance + Limit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.monthName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text("Balance")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(isPositive ? .green : .red)
                        .font(.headline)
                }

                Text(balance, format: .currency(code: "IDR").precision(.fractionLength(0)))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isPositive ? Color.green : Color.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer()

                // Monthly limit bar
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Monthly Limit")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(spendingRatio * 100))% used")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(spendingRatio >= 0.9 ? .red : .secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.9), .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(spendingRatio), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            // Separator
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(width: 0.5)
                .padding(.vertical, 10)

            // MARK: Right Panel - Income & Expense bars
            VStack(alignment: .leading, spacing: 10) {
                // Income
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Income")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    Text(data.totalIncome, format: .currency(code: "IDR").precision(.fractionLength(0)))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.8), .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(incomeRatio), height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                // Expense
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("Expense")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    Text(data.totalExpense, format: .currency(code: "IDR").precision(.fractionLength(0)))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.red.opacity(0.8), .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(expenseRatio), height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 8))
                    Text("Updated \(data.lastUpdated, style: .relative) ago")
                        .font(.system(size: 8))
                }
                .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Medium - Normal") {
    MediumWidgetView(data: .placeholder)
        .frame(width: 338, height: 158)
        .border(Color.gray)
}

#Preview("Medium - Over Limit") {
    MediumWidgetView(
        data: WidgetData(
            totalIncome: 3_000_000,
            totalExpense: 4_500_000,
            monthlySpendingLimit: 4_000_000,
            monthName: "August",
            lastUpdated: .now
        )
    )
    .frame(width: 338, height: 158)
    .border(Color.gray)
}

#Preview("Medium - Empty") {
    MediumWidgetView(data: .empty)
        .frame(width: 338, height: 158)
        .border(Color.gray)
}
