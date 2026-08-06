//
//  MonthlySpendingCardView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/07/26.
//

import SwiftUI

struct MonthlySpendingCardView: View {
    var totalIncome: Double
    var totalExpense: Double
    var monthlySpendingLimit: Double
    
    private var totalBalance: Double {
        return totalIncome - totalExpense
    }
    
    private var totalVolume: Double {
        return totalIncome + totalExpense
    }
    
    private var incomeRatio: Double {
        guard totalVolume > 0 else { return 0.0 }
        return totalIncome / totalVolume
    }
    
    private var expenseRatio: Double {
        guard totalVolume > 0 else { return 0.0 }
        return 1.0 - incomeRatio
    }
    
    private var spendingLimitRatio: Double {
        guard monthlySpendingLimit > 0 else { return 0 }
        return min(totalExpense / monthlySpendingLimit, 1.0)
    }
    
    @ViewBuilder
    private var illustrationImage: some View {
        Group {
            if totalBalance >= 0 {
                Image(systemName: Icon.goodBalance)
                    .foregroundStyle(Color.green.opacity(0.8))
            } else {
                Image(systemName: Icon.badBalance)
                    .foregroundStyle(Color.red.opacity(0.8))
            }
        }
        .font(.title2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Balance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(totalBalance, format: .currency(code: "IDR"))
                        .font(.title2)
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            totalBalance >= 0 ? Color.green : Color.red
                        )
                }
                
                Spacer()
                
                illustrationImage
            }
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        "Income: \(totalIncome, format: .currency(code: "IDR").precision(.fractionLength(0)))"
                    )
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                                .shadow(
                                    color: Color.black.opacity(0.12),
                                    radius: 2,
                                    x: 0,
                                    y: 2
                                )
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .green.opacity(0.85), .green,
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: geometry.size.width
                                    * CGFloat(incomeRatio),
                                    height: 10
                                )
                                .shadow(
                                    color: .green.opacity(0.4),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                                .animation(
                                    .spring(
                                        response: 0.4,
                                        dampingFraction: 0.7
                                    ),
                                    value: totalBalance
                                )
                        }
                    }
                    .frame(height: 10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        "Expense: \(totalExpense, format: .currency(code: "IDR").precision(.fractionLength(0)))"
                    )
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                                .shadow(
                                    color: Color.black.opacity(0.12),
                                    radius: 2,
                                    x: 0,
                                    y: 2
                                )
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .red.opacity(0.85), .red,
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: geometry.size.width
                                    * CGFloat(expenseRatio),
                                    height: 10
                                )
                                .shadow(
                                    color: .red.opacity(0.4),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                                .animation(
                                    .spring(
                                        response: 0.4,
                                        dampingFraction: 0.7
                                    ),
                                    value: totalBalance
                                )
                        }
                    }
                    .frame(height: 10)
                }
            }
            
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                
                Text("Monthly Limit:  \(monthlySpendingLimit, format: .currency(code: "IDR"))")
                
                Text("(\(Int(spendingLimitRatio * 100))% used)")
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
        }
        .padding(.all, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.secondarySystemGroupedBackground),
                            Color(.secondarySystemGroupedBackground)
                                .opacity(0.95),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Expense = 0
            MonthlySpendingCardView(
                totalIncome: 45_000_000,
                totalExpense: 0,
                monthlySpendingLimit: 2000000.0
            )
            
            // Income = 0
            MonthlySpendingCardView(
                totalIncome: 0,
                totalExpense: 100_000_000,
                monthlySpendingLimit: 2000000.0
            )
            
            // Other case
            MonthlySpendingCardView(
                totalIncome: 150000,
                totalExpense: 500000,
                monthlySpendingLimit: 2000000.0
            )
            
            // Both are 0
            MonthlySpendingCardView(
                totalIncome: 0,
                totalExpense: 0,
                monthlySpendingLimit: 2000000.0
            )
        }
    }
}
