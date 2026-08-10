//
//  SmallWidgetView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 10/08/26.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let data: WidgetData

    private var balance: Double { data.totalIncome - data.totalExpense }
    private var isPositive: Bool { balance >= 0 }

    private var spendingRatio: Double {
        guard data.monthlySpendingLimit > 0 else { return 0 }
        return min(data.totalExpense / data.monthlySpendingLimit, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.monthName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("Balance")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isPositive ? .green : .red)
                    .font(.title3)
            }

            Text(balance, format: .currency(code: "IDR").precision(.fractionLength(0)))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(isPositive ? Color.green : Color.red)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("Limit used")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

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
                            .frame(width: geo.size.width * CGFloat(spendingRatio), height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(Int(spendingRatio * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(spendingRatio >= 0.9 ? .red : .secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

#Preview("Small - Normal") {
    SmallWidgetView(data: .placeholder)
        .frame(width: 158, height: 158)
        .border(Color.gray)
}

#Preview("Small - Over Limit") {
    SmallWidgetView(
        data: WidgetData(
            totalIncome: 3_000_000,
            totalExpense: 4_500_000,
            monthlySpendingLimit: 4_000_000,
            monthName: "August",
            lastUpdated: .now
        )
    )
    .frame(width: 158, height: 158)
    .border(Color.gray)
}

#Preview("Small - Empty") {
    SmallWidgetView(data: .empty)
        .frame(width: 158, height: 158)
        .border(Color.gray)
}
