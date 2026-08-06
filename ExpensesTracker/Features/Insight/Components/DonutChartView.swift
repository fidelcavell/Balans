//
//  DonutChartView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 20/07/26.
//

import SwiftUI
import Charts

struct DonutChartView: View {
    var currentMonthTransaction: MonthlyTransaction?
    @Binding var selectedSector: String?
    var totalTransactionExpenseByMonth: Double
    var activeCategory: ExpenseLabel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let currentData = currentMonthTransaction {
                Chart(currentData.labels) { item in
                    let isSelected = selectedSector == item.label.title
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(isSelected ? 0.58 : 0.66),
                        outerRadius: .ratio(isSelected ? 1.0 : 0.94),
                        angularInset: 2
                    )
                    .foregroundStyle(item.label.tint)
                    .cornerRadius(5)
                    .opacity(selectedSector == nil || isSelected ? 1.0 : 0.4)
                }
                .chartAngleSelection(value: $selectedSector.mappedToCategory(in: currentData.labels, total: totalTransactionExpenseByMonth))
                .frame(height: 170)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedSector)
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        if let activeCategory {
                            Image(systemName: activeCategory.label.symbol)
                                .font(.footnote)
                                .foregroundStyle(activeCategory.label.tint)
                            Text(activeCategory.label.title)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f%%", (activeCategory.amount / totalTransactionExpenseByMonth) * 100))
                                .font(.footnote.bold())
                        } else {
                            Text("Total Expenses")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(totalTransactionExpenseByMonth, format: .currency(code: "IDR"))
                                .font(.caption.bold())
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                        }
                    }
                    .padding(40)
                    .id(selectedSector ?? "total")
                    .transition(.scale.combined(with: .opacity))
                }
            } else {
                ContentUnavailableView("No Data Available", systemImage: Icon.pieChart, description: Text("Try picking another timeframe."))
                    .frame(height: 170)
            }
        }
    }
}

// MARK: - Extension Helper
extension Binding where Value == String? {
    func mappedToCategory(in labels: [ExpenseLabel], total: Double) -> Binding<Double?> {
        Binding<Double?>(
            get: { return nil },
            set: { newValue in
                guard let newValue else {
                    self.wrappedValue = nil
                    return
                }
                var accumulatedSum: Double = 0
                for item in labels {
                    accumulatedSum += item.amount
                    if newValue <= accumulatedSum {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            self.wrappedValue = item.label.title
                        }
                        break
                    }
                }
            }
        )
    }
}
