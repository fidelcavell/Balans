//
//  MonthlySpendingCardView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/07/26.
//

import SwiftUI

struct MonthlySpendingCardView: View {
    var totalSpending: Double = 100000000
    var spendingLimit: Double = 120000000
    
    private var spendingRatio: Double {
        guard spendingLimit > 0 else { return 0 }
        return min(totalSpending / spendingLimit, 1.0)
    }
    
    private var progressBarColor: Color {
        if spendingRatio >= 0.9 {
            return .red
        } else if spendingRatio >= 0.75 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Spending")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(totalSpending, format: .currency(code: "IDR").locale(Locale(identifier: "id_ID")))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.title2)
                    .foregroundColor(progressBarColor.opacity(0.8))
                
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(progressBarColor.opacity(0.8))
                
                Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                    .font(.title2)
                    .foregroundColor(progressBarColor.opacity(0.8))
            }
            
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                            .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 2)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [progressBarColor.opacity(0.85), progressBarColor]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(spendingRatio), height: 10)
                            .shadow(color: progressBarColor.opacity(0.4), radius: 4, x: 0, y: 2)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: totalSpending)
                    }
                }
                .frame(height: 10)
            }
            
            HStack {
                Text("Limit: \(spendingLimit, format: .currency(code: "IDR").locale(Locale(identifier: "id_ID")))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(spendingRatio * 100))% Used")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(progressBarColor)
            }
        }
        .padding(.all, 20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground).opacity(0.95)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.7), Color.clear, Color.black.opacity(0.03)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Safe Mode Example
            MonthlySpendingCardView(totalSpending: 45000000, spendingLimit: 100000000)
            
            // Warning Mode Example
            MonthlySpendingCardView(totalSpending: 82000000, spendingLimit: 100000000)
            
            // Critical Over-budget Example
            MonthlySpendingCardView(totalSpending: 105000000, spendingLimit: 100000000)
        }
    }
}
