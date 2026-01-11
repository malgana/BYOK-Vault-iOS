//
//  ValidationService.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import Foundation

final class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // Валидация API ключа для разных платформ
    func validateKey(_ key: String, platform: String) async -> ValidationResult {
        // Базовая проверка формата
        guard !key.isEmpty else {
            return .failure(error: "Ключ не может быть пустым")
        }
        
        // Проверка формата для известных платформ
        switch platform {
        case "Anthropic":
            return await validateAnthropicKey(key)
        case "OpenAI":
            return await validateOpenAIKey(key)
        case "Google AI":
            return await validateGoogleAIKey(key)
        default:
            // Для неизвестных платформ просто проверяем что ключ не пустой
            return .success(message: "Ключ сохранен (валидация недоступна)")
        }
    }
    
    // MARK: - Anthropic
    private func validateAnthropicKey(_ key: String) async -> ValidationResult {
        // Проверка формата ключа Anthropic (обычно начинается с sk-ant-)
        guard key.hasPrefix("sk-ant-") else {
            return .failure(error: "Неверный формат ключа Anthropic (должен начинаться с sk-ant-)")
        }
        
        // TODO: Реальная проверка через API
        // Пока возвращаем успех если формат правильный
        return .success(message: "Формат ключа корректен")
    }
    
    // MARK: - OpenAI
    private func validateOpenAIKey(_ key: String) async -> ValidationResult {
        // Проверка формата ключа OpenAI (обычно начинается с sk-)
        guard key.hasPrefix("sk-") else {
            return .failure(error: "Неверный формат ключа OpenAI (должен начинаться с sk-)")
        }
        
        // TODO: Реальная проверка через API
        return .success(message: "Формат ключа корректен")
    }
    
    // MARK: - Google AI
    private func validateGoogleAIKey(_ key: String) async -> ValidationResult {
        // Google AI ключи обычно имеют определенную длину
        guard key.count >= 20 else {
            return .failure(error: "Ключ слишком короткий")
        }
        
        // TODO: Реальная проверка через API
        return .success(message: "Формат ключа корректен")
    }
    
    // MARK: - Получение статистики
    func fetchStatistics(for key: String, platform: String) async -> StatisticsResult? {
        switch platform {
        case "Anthropic":
            return await fetchAnthropicStatistics(key)
        case "OpenAI":
            return await fetchOpenAIStatistics(key)
        default:
            return nil
        }
    }
    
    private func fetchAnthropicStatistics(_ key: String) async -> StatisticsResult? {
        // TODO: Реальный запрос к Anthropic API
        // https://docs.anthropic.com/en/api/usage
        
        // Временная заглушка
        return StatisticsResult(
            totalSpent: 15.30,
            tokensUsed: 2_500_000
        )
    }
    
    private func fetchOpenAIStatistics(_ key: String) async -> StatisticsResult? {
        // TODO: Реальный запрос к OpenAI API
        // https://platform.openai.com/docs/api-reference/usage
        
        // Временная заглушка
        return StatisticsResult(
            totalSpent: 8.20,
            tokensUsed: 1_200_000
        )
    }
}

// MARK: - Result Types
enum ValidationResult {
    case success(message: String)
    case failure(error: String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

struct StatisticsResult {
    let totalSpent: Double
    let tokensUsed: Int
}
