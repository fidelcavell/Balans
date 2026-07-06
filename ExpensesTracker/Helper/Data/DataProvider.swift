//
//  DataProvider.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 22/06/26.
//

import Foundation
import SwiftData

@MainActor
class DataProvider {
    static let shared = DataProvider()
    
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
        do {
            /// Put all used data model in the schema array
            let schema = Schema([
                Preference.self,
                Transaction.self,
                TransactionLabel.self
            ])
            
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            /// Act as Single source of truth container
            self.container = try ModelContainer(for: schema, configurations: [config])
            self.context = container.mainContext
            
            /// Initialize permanent transaction label
            seedInitialData()
            
        } catch {
            fatalError("[DataProvider] Failed to initialize SwiftData: \(error.localizedDescription)")
        }
    }
    
    private func seedInitialData() {
        let labelDescriptor = FetchDescriptor<TransactionLabel>()
        
        if let existingLabels = try? context.fetch(labelDescriptor), existingLabels.isEmpty {
            for label in TransactionLabel.defaults {
                context.insert(label)
            }
            print("[DataProvider] Default Transaction Labels seeded!")
        }
        
        try? context.save()
    }
}
