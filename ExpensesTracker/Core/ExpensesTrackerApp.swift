//
//  ExpensesTrackerApp.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/05/26.
//

import SwiftUI
import SwiftData

@main
struct ExpensesTrackerApp: App {
    let dataProvider = DataProvider.shared
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .ignoresSafeArea()
        }
        .modelContainer(dataProvider.container)
    }
}
