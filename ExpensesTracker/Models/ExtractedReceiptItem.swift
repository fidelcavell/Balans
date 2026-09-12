//
//  ExtractedReceiptItem.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 11/09/26.
//

import Foundation

public struct ExtractedReceiptItem: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var price: Double
    public var quantity: Int

    public init(id: UUID = UUID(), name: String, price: Double, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = max(1, quantity)
    }

    public var totalPrice: Double {
        price * Double(max(1, quantity))
    }

    public mutating func updateQuantity(_ newQuantity: Int) {
        self.quantity = max(1, newQuantity)
    }

    public mutating func updatePrice(_ newPrice: Double) {
        self.price = max(0, newPrice)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case quantity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
    }
}
