//
//  APIKey.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import Foundation
import SwiftData

@Model
final class APIKey {
    var myName: String // Пользовательское название ключа
    var keychainID: String // UUID для доступа к ключу в Keychain
    var dateAdded: Date
    var isValid: Bool
    
    // Статистика (только для платформ с поддержкой)
    var totalSpent: Double? // В долларах
    var tokensUsed: Int?
    var lastStatisticsUpdate: Date?
    
    @Relationship
    var platform: Platform?
    
    init(myName: String, platform: Platform) {
        self.myName = myName
        self.platform = platform
        self.keychainID = UUID().uuidString
        self.dateAdded = Date()
        self.isValid = false
    }
    
    // Форматированная сумма
    var formattedSpent: String {
        guard let spent = totalSpent else { return "—" }
        return String(format: "$%.2f", spent)
    }
    
    // Форматированные токены
    var formattedTokens: String {
        guard let tokens = tokensUsed else { return "—" }
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }
}
