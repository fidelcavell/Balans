//
//  StateMessage.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 05/07/26.
//

import Foundation

enum StateMessage: Identifiable, Equatable {
    case success(String)
    case failure(String)
    
    var id: String {
        switch self {
        case .success(let msg), .failure(let msg): return msg
        }
    }
    
    var text: String {
        switch self {
        case .success(let msg), .failure(let msg): return msg
        }
    }
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
