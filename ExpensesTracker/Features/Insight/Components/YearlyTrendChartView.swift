//
//  YearlyTrendChartView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 21/07/26.
//

import SwiftUI
import Charts

struct YearlyTrendChartView: View {
    var yearlyTrendData: [MonthlyTransaction]
    var totalYearlyIncome: Double
    var totalYearlyExpenses: Double
    var yearlyNetSavings: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 7, height: 7)
                        Text("Income")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                    Text(totalYearlyIncome, format: .currency(code: "IDR").notation(.compactName))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                        Text("Expenses")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                    Text(totalYearlyExpenses, format: .currency(code: "IDR").notation(.compactName))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(yearlyNetSavings >= 0 ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text("Net Savings")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                    Text(yearlyNetSavings, format: .currency(code: "IDR").notation(.compactName))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(yearlyNetSavings >= 0 ? .green : .orange)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            if !yearlyTrendData.isEmpty {
                Chart {
                    ForEach(yearlyTrendData) { point in
                        // Income Bar
                        BarMark(
                            x: .value("Month", point.monthName),
                            y: .value("Amount", point.totalIncome)
                        )
                        .foregroundStyle(.blue.gradient)
                        .position(by: .value("Type", "Income"))
                        .cornerRadius(4)
                        
                        // Expenses Bar
                        BarMark(
                            x: .value("Month", point.monthName),
                            y: .value("Amount", point.totalExpenses)
                        )
                        .foregroundStyle(.red.gradient)
                        .position(by: .value("Type", "Expenses"))
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color(.separator))
                        AxisValueLabel(format: .currency(code: "IDR").notation(.compactName))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 140)
            } else {
                ContentUnavailableView("No Data Available", systemImage: Icon.xyAxisLineChart, description: Text("Add transactions to preview yearly trends."))
                    .frame(height: 140)
            }
        }
    }
}
