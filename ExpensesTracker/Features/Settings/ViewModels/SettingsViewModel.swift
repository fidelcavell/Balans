//
//  SettingsViewModel.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/07/26.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - Dependencies
    private let context = DataProvider.shared.context
    
    // MARK: - Published State
    var message: StateMessage? = nil
    
    // MARK: - Functions
    /// Add new preference record
    func addUpdatePreference(id: UUID? = nil, name: String, monthlySpendingLimit: Int) {
        if let existingId = id {
            let descriptor = FetchDescriptor<Preference>(
                predicate: #Predicate { $0.id == existingId }
            )
            
            if let existingPreference = try? context.fetch(descriptor).first {
                existingPreference.name = name
                existingPreference.monthlySpendingLimit = monthlySpendingLimit
                
                save()
                self.message = .success("Your preference has been updated!")
                return
            }
        }
        
        let newPreference = Preference(
            name: name,
            monthlySpendingLimit: monthlySpendingLimit
        )
        
        context.insert(newPreference)
        
        save()
        self.message = .success("New Preference has been added!")
    }
    
    // MARK: - Internal Helpers
    private func save() {
        do {
            try context.save()
        } catch {
            self.message = .failure("Failed to perform your request. Please try again. Error: \(error.localizedDescription)")
            print("[Settings VM] Save error: \(error.localizedDescription)")
        }
    }
}
