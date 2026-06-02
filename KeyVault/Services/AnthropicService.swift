//
//  AnthropicService.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import Foundation

actor AnthropicService {
    static let shared = AnthropicService()
    
    private init() {}
    
    enum ValidationResult {
        case valid
        case invalid(String)       // Ключ точно неверный - не сохраняем
        case serverError(String)   // Проблемы сервера - сохраняем без валидации
        case networkError(String)  // Нет сети - показываем ошибку
    }
    
    /// Валидация API ключа через минимальный запрос
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Минимальный запрос для проверки ключа
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1,
            "messages": [
                ["role": "user", "content": "Hi"]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .networkError("Ошибка формирования запроса")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .serverError("Неверный ответ сервера")
            }
            
            switch httpResponse.statusCode {
            case 200:
                return .valid
            case 401:
                return .invalid("Неверный API ключ")
            case 403:
                return .invalid("Ключ заблокирован")
            case 429:
                // Rate limit - но ключ валидный
                return .valid
            case 500, 529:
                // Проблемы сервера - сохраняем без валидации
                return .serverError("Сервер недоступен")
            default:
                // Пробуем получить сообщение об ошибке
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .invalid(message)
                }
                return .serverError("Код ошибки: \(httpResponse.statusCode)")
            }
        } catch {
            return .networkError("Нет подключения к сети")
        }
    }
}
