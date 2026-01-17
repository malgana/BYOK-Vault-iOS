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
            print("❌ [OpenAI] Ошибка формирования запроса: \(error)")
            return .networkError("Ошибка формирования запроса")
        }
        
        print("🔄 [OpenAI] Отправляем запрос на валидацию...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [OpenAI] Неверный ответ сервера")
                return .serverError("Неверный ответ сервера")
            }
            
            print("📡 [OpenAI] HTTP статус: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [OpenAI] Ответ: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                print("✅ [OpenAI] Ключ валиден!")
                return .valid
            case 401:
                print("❌ [OpenAI] Неверный API ключ")
                return .invalid("Неверный API ключ")
            case 403:
                print("❌ [OpenAI] Ключ заблокирован")
                return .invalid("Ключ заблокирован")
            case 429:
                print("⚠️ [OpenAI] Rate limit, но ключ валиден")
                return .valid
            case 500, 502, 503:
                print("⚠️ [OpenAI] Сервер недоступен")
                return .serverError("Сервер недоступен")
            default:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("❌ [OpenAI] Ошибка: \(message)")
                    return .invalid(message)
                }
                print("❌ [OpenAI] Неизвестная ошибка, код: \(httpResponse.statusCode)")
                return .serverError("Код ошибки: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ [OpenAI] Ошибка сети: \(error.localizedDescription)")
            return .networkError("Нет подключения к сети")
        }
    }
}
