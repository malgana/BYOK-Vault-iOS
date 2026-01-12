//
//  Platform.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Platform {
    var name: String
    var dateCreated: Date
    var customIconData: Data? // Кастомная иконка пользователя
    
    @Relationship(deleteRule: .cascade, inverse: \APIKey.platform)
    var apiKeys: [APIKey] = []
    
    init(name: String, customIconData: Data? = nil) {
        self.name = name
        self.dateCreated = Date()
        self.customIconData = customIconData
    }
    
    // Проверка, является ли платформа предустановленной
    var isDefault: Bool {
        Self.defaultPlatforms.contains(name)
    }
    
    // Имя иконки в Assets для предустановленных платформ
    var assetIconName: String? {
        guard isDefault else { return nil }
        
        switch name {
        case "Anthropic": return "anthropic"
        case "OpenAI": return "openai"
        case "Google AI": return "google-ai"
        case "Hailuo": return "hailuo"
        case "DeepSeek": return "deepseek"
        case "Reve AI": return "reve-ai"
        case "GitHub": return "github"
        case "Google Image Search": return "google-image-search"
        default: return nil
        }
    }
    
    // Предустановленные платформы
    static let defaultPlatforms = [
        "Anthropic",
        "OpenAI",
        "Google AI",
        "Hailuo",
        "DeepSeek",
        "Reve AI",
        "GitHub",
        "Google Image Search"
    ]
}
