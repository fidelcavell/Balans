//
//  Router.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/07/26.
//

import SwiftUI
import Foundation
import Observation

// MARK: - Define the possible app route
enum AppRoute: Hashable {
    case newTransaction
    case voiceTranscription
    case cameraFastVLM
    case detailTransaction(Transaction)
}

// MARK: - App Router Coordinator
@Observable
@MainActor
final class Router {
    var path = NavigationPath()
    
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
