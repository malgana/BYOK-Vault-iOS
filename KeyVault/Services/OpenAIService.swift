//
//  OpenAIService.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 17.01.26.
//

import Foundation

actor OpenAIService {
    static let shared = OpenAIService()
    
    private init() {}
    
    enum ValidationResult {
        case valid
        case invalid(String)
        case serverError(String)
        case networkError(String)
    }
    
    /// Валидация API ключа через минимальный запрос
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
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
                return .valid
            case 500, 502, 503:
                return .serverError("Сервер недоступен")
            default:
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
