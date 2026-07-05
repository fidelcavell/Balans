//
//  TransactionType.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 04/07/26.
//

import Foundation

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case inflow
    case outflow
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .inflow:  return "Income"
        case .outflow: return "Expense"
        }
    }
}
