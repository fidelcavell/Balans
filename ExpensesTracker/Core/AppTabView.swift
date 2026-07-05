//
//  AppTabView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/05/26.
//

import SwiftUI
import SwiftData

struct AppTabView: View {
    @State private var router = Router()
    
    var body: some View {
        TabView {
            Tab("", systemImage: "creditcard") {
                TransactionView()
            }
            
            Tab("", systemImage: "lightbulb.max") {
                InsightView()
            }
            
            Tab("", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .environment(router)
    }
}

#Preview {
    AppTabView()
}
