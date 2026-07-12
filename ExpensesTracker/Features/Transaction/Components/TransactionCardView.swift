//
//  TransactionCardView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 30/06/26.
//

import SwiftUI
import SwiftData

struct TransactionCardView: View {
    @Environment(Router.self) private var router
    
    let transaction: Transaction
    
    @State private var isAnimated = false
    
    var categoryName: String {
        transaction.label?.title ?? "No Category"
    }
    
    var categoryIcon: String {
        transaction.label?.symbol ?? "questionmark.circle"
    }
    
    var categoryColor: Color {
        transaction.label?.tint ?? .gray
    }
    
    var amount: Double {
        transaction.amount
    }
    
    var isIncome: Bool {
        transaction.type == .inflow
    }
    
    var descriptionString: String {
        transaction.note.isEmpty ? "-" : transaction.note
    }
    
    var body: some View {
        @Bindable var router = router
        
        Button {
            router.navigate(to: .detailTransaction(transaction))
        } label: {
            HStack(spacing: 16) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 24))
                    .foregroundColor(categoryColor)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(categoryColor.opacity(0.15)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(descriptionString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    Text(formatCompactCurrency(amount))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(isIncome ? .green : .red)
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            // Outer spacing between multiple cards
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            
            // Animation Modifiers
            .opacity(isAnimated ? 1.0 : 0.0)
            .scaleEffect(isAnimated ? 1.0 : 0.92)
            .offset(y: isAnimated ? 0 : 15)
            .onAppear {
                // Smooth spring animation on load
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                    isAnimated = true
                }
            }
        }
    }
    
    // Helper function to compress large numbers (e.g., 100000 -> 100rb)
    private func formatCompactCurrency(_ value: Double) -> String {
        let suffix = ["", "rb", "jt", "M", "T"]
        var index = 0
        var num = value
        
        while num >= 1000 && index < suffix.count - 1 {
            num /= 1000
            index += 1
        }
        
        // If it was formatted (index > 0), show 1 decimal place if needed (e.g., 100.5rb)
        // Otherwise, format normally
        if index > 0 {
            let formattedNum = num.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", num) : String(format: "%.1f", num)
            let indonesianDecimal = formattedNum.replacingOccurrences(of: ".", with: ",")
            
            return "Rp \(indonesianDecimal)\(suffix[index])"
        } else {
            return String(format: "Rp %.0f", value)
        }
    }
}

#Preview {
    let mockLabel = TransactionLabel(title: "Investment", symbol: "person.fill", tint: .blue)
    let mockTransaction = Transaction(occurredAt: Date(), amount: 100000.0, type: .inflow, note: "Quarterly stock dividend payout from tech portfolio")
    mockTransaction.label = mockLabel
    
    return TransactionCardView(transaction: mockTransaction)
}
