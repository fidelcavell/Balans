//
//  BreakdownCategoriesCardView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 21/07/26.
//

import SwiftUI

struct BreakdownCategoriesCardView: View {
    var currentMonthLabels: [ExpenseLabel]
    var totalTransactionExpenseByMonth: Double
    @Binding var selectedSector: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown Categories")
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if !currentMonthLabels.isEmpty {
                    ForEach(currentMonthLabels) { item in
                        let percentage = totalTransactionExpenseByMonth > 0 ? (item.amount / totalTransactionExpenseByMonth) * 100 : 0
                        let isSelected = selectedSector == item.label.title
                        
                        HStack(spacing: 16) {
                            Image(systemName: item.label.symbol)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(item.label.tint, in: Circle())
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.label.title)
                                    .font(.body)
                                    .fontWeight(isSelected ? .bold : .medium)
                                Text(item.amount, format: .currency(code: "IDR"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.1f%%", percentage))
                                .font(.body.bold())
                                .foregroundStyle(isSelected ? item.label.tint : .secondary)
                        }
                        .padding()
                        .background(isSelected ? item.label.tint.opacity(0.12) : Color.clear)
                        .contentShape(Rectangle())
                    }
                } else {
                    ContentUnavailableView("No Category Breakdown", systemImage: Icon.tray, description: Text("No expenses recorded for this selection."))
                        .padding(.vertical, 24)
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
