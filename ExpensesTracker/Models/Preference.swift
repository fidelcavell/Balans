//
//  Preference.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 05/07/26.
//

import Foundation
import SwiftData

@Model
final class Preference {
    @Attribute(.unique)
    var id: UUID
    
    var name: String
    var currentSpending: Int
    var monthlySpendingLimit: Int
    
    init(id: UUID = UUID(), name: String, currentSpending: Int = 0, monthlySpendingLimit: Int = 0) {
        self.id = id
        self.name = name
        self.currentSpending = currentSpending
        self.monthlySpendingLimit = monthlySpendingLimit
    }
}
