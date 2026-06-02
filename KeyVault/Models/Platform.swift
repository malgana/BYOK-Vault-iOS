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
    var dashboardURL: String? // Ссылка на личный кабинет платформы
    
    @Relationship(deleteRule: .cascade, inverse: \APIKey.platform)
    var apiKeys: [APIKey] = []
    
    @Relationship(deleteRule: .cascade, inverse: \KeyGroup.platform)
    var groups: [KeyGroup] = []
    
    init(name: String, customIconData: Data? = nil, dashboardURL: String? = nil) {
        self.name = name
        self.dateCreated = Date()
        self.customIconData = customIconData
        self.dashboardURL = dashboardURL
    }

    /// URL кабинета: сохранённый или встроенный по умолчанию
    var resolvedDashboardURL: String? {
        if let dashboardURL, !dashboardURL.isEmpty {
            return dashboardURL
        }
        return Self.defaultDashboardURL(for: name)
    }
    
    // Проверка, является ли платформа предустановленной
    var isDefault: Bool {
        Self.defaultPlatforms.contains(name) || Self.legacyPlatformNames.contains(name)
    }
    
    // Имя иконки в Assets для предустановленных платформ
    var assetIconName: String? {
        guard isDefault else { return nil }
        return Self.assetIconName(for: name)
    }

    static func assetIconName(for name: String) -> String? {
        switch canonicalPlatformName(name) {
        case "Claude": return "anthropic"
        case "GPT": return "openai"
        case "Gemini": return "google-ai"
        case "Hailuo": return "hailuo"
        case "DeepSeek": return "deepseek"
        case "Reve AI": return "reve-ai"
        case "GitHub": return "github"
        case "Google Image Search": return "google-image-search"
        case "Grok": return "xai"
        case "Qwen": return "qwen"
        case "Meta Muse-Spark": return "meta-muse-spark"
        default: return nil
        }
    }

    /// Старые имена платформ → актуальные (для импорта и миграции базы)
    static let legacyNameMigrations: [String: String] = [
        "Anthropic": "Claude",
        "OpenAI": "GPT",
        "xAI": "Grok"
    ]

    static var legacyPlatformNames: Set<String> {
        Set(legacyNameMigrations.keys)
    }

    static func canonicalPlatformName(_ name: String) -> String {
        legacyNameMigrations[name] ?? name
    }

    static let defaultDashboardURLs: [String: String] = [
        "Claude": "https://console.anthropic.com/",
        "GPT": "https://platform.openai.com/api-keys",
        "Gemini": "https://aistudio.google.com/apikey",
        "Grok": "https://console.x.ai/",
        "DeepSeek": "https://platform.deepseek.com/api_keys",
        "Qwen": "https://dashscope.console.aliyun.com/apiKey",
        "Hailuo": "https://www.minimax.io/platform",
        "Reve AI": "https://reve.com/",
        "GitHub": "https://github.com/settings/tokens",
        "Google Image Search": "https://programmablesearchengine.google.com/controlpanel/all",
        "Meta Muse-Spark": "https://developers.meta.com/ai/"
    ]

    static func defaultDashboardURL(for name: String) -> String? {
        defaultDashboardURLs[canonicalPlatformName(name)]
    }

    static func applyDefaultDashboardURLs(in context: ModelContext) {
        guard let allPlatforms = try? context.fetch(FetchDescriptor<Platform>()) else { return }

        var didChange = false
        for platform in allPlatforms where platform.dashboardURL == nil || platform.dashboardURL?.isEmpty == true {
            if let url = defaultDashboardURL(for: platform.name) {
                platform.dashboardURL = url
                didChange = true
            }
        }

        if didChange {
            try? context.save()
        }
    }

    static func migrateLegacyNames(in context: ModelContext) {
        guard let allPlatforms = try? context.fetch(FetchDescriptor<Platform>()) else { return }

        var didChange = false
        for platform in allPlatforms {
            guard let newName = legacyNameMigrations[platform.name] else { continue }

            if let existing = allPlatforms.first(where: { $0.name == newName }), existing !== platform {
                for key in platform.apiKeys {
                    key.platform = existing
                }
                context.delete(platform)
            } else {
                platform.name = newName
            }
            didChange = true
        }

        if didChange {
            try? context.save()
        }
    }
    
    // Предустановленные платформы
    static let defaultPlatforms = [
        "Claude",
        "GPT",
        "Gemini",
        "Hailuo",
        "DeepSeek",
        "Reve AI",
        "GitHub",
        "Google Image Search",
        "Grok",
        "Qwen",
        "Meta Muse-Spark"
    ]
}
