//
//  Platform.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import Foundation
import SwiftData

@Model
final class Platform {
    var name: String
    var dateCreated: Date
    
    @Relationship(deleteRule: .cascade, inverse: \APIKey.platform)
    var apiKeys: [APIKey] = []
    
    init(name: String) {
        self.name = name
        self.dateCreated = Date()
    }
    
    // Предустановленные платформы
    static let defaultPlatforms = [
        "Anthropic",
        "OpenAI",
        "Google AI",
        "Hailuo",
        "DeepSeek",
        "Reve AI"
    ]
}
