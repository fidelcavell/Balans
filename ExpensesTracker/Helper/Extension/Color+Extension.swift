//
//  Color+Extension.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 06/06/26.
//

import Foundation
import SwiftUI
import UIKit
typealias PlatformColor = UIColor

extension Color {
    // --- KEEP YOUR EXISTING CODE ---
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        guard let rgb = UInt64(hex, radix: 16) else {
            self = .black
            return
        }
        
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
    
    // --- ADD THIS NEW FUNCTION ---
    func toHex() -> String? {
        let uiColor = PlatformColor(self)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        // Extract components
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }
        
        // Format as a hex string
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
    
    // --- KEEP YOUR EXISTING DYNAMIC STYLES ---
    static func dynamic(light: String, dark: String) -> Color {
        return Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
            }
        )
    }
    
    static let primaryBrand = Color.dynamic(
        light: "#2A6F6F",
        dark: "#4A9B9B"
    )
    
    static let secondaryBrand = Color.dynamic(
        light: "#6B7280",
        dark: "#A1A8B3"
    )
    
    static let accentBrand = Color.dynamic(
        light: "#E76F51",
        dark: "#F28B74"
    )
}
