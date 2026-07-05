//
//  Transaction.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/06/26.
//

//import Foundation
//import SwiftData
//import SwiftUI
//
//enum TransactionTypex {
//    
//}
//
//@Model
//final class Transactionx {
//    @Attribute(.unique)
//    var id: UUID
//    
//    var date: Date
//    var amount: Double
//    var type: TransactionTypex
//    
//    var category: TransactionCategoryx? = nil
//    
//    var desc: String
//    var createdAt: Date
//    
//    init(id: UUID = UUID(), date: Date, amount: Double, type: TransactionTypex, desc: String = "-") {
//        self.id = id
//        self.date = date
//        self.amount = amount
//        self.type = type
//        self.desc = desc
//        self.createdAt = .now
//    }
//}
//
//@Model
//final class TransactionCategoryx {
//    @Attribute(.unique)
//    var id: UUID
//    
//    var name: String
//    var icon: String
//    var colorHex: String
//    var isDefault: Bool
//    
//    @Relationship(deleteRule: .cascade, inverse: \Transactionx.category)
//    var transactions: [Transactionx] = []
//    
//    init(id: UUID = UUID(), name: String, icon: String, color: Color, isDefault: Bool = false) {
//        self.id = id
//        self.name = name
//        self.icon = icon
//        self.colorHex = color.toHex() ?? "#FFFFFF"
//        self.isDefault = isDefault
//    }
//    
//    // Computed variable (Convert String Hex to actual Color)
//    var color: Color {
//        get { Color(hex: colorHex) }
//        set { colorHex = newValue.toHex() ?? "#FFFFFF" }
//    }
//}
//
//extension TransactionCategoryx {
//    static var sampleCategories: [TransactionCategoryx] {
//        [
//            TransactionCategoryx(name: "Food", icon: "fork.knife", color: .orange, isDefault: true),
//            TransactionCategoryx(name: "Transportation", icon: "car.fill", color: .blue, isDefault: true),
//            TransactionCategoryx(name: "Shopping", icon: "bag.fill", color: .purple, isDefault: true),
//            TransactionCategoryx(name: "Bills", icon: "doc.text.fill", color: .red, isDefault: true),
//            TransactionCategoryx(name: "Salary", icon: "banknote.fill", color: .green, isDefault: true),
//            TransactionCategoryx(name: "Entertainment", icon: "gamecontroller.fill", color: .pink, isDefault: true)
//        ]
//    }
//}
