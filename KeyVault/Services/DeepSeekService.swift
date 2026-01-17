//
//  DeepSeekService.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 17.01.26.
//

import Foundation

actor DeepSeekService {
    static let shared = DeepSeekService()
    
    private init() {}
    
    enum ValidationResult {
        case valid
        case invalid(String)       // Ключ точно неверный - не сохраняем
        case serverError(String)   // Проблемы сервера - сохраняем без валидации
        case networkError(String)  // Нет сети - показываем ошибку
    }
    
    /// Валидация API ключа через минимальный запрос
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Минимальный запрос для проверки ключа
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "max_tokens": 1,
            "messages": [
                ["role": "user", "content": "Hi"]
            ],
            "stream": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ [DeepSeek] Ошибка формирования запроса: \(error)")
            return .networkError("Ошибка формирования запроса")
        }
        
        print("🔄 [DeepSeek] Отправляем запрос на валидацию...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [DeepSeek] Неверный ответ сервера")
                return .serverError("Неверный ответ сервера")
            }
            
            print("📡 [DeepSeek] HTTP статус: \(httpResponse.statusCode)")
            
            // Выводим тело ответа для отладки
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [DeepSeek] Ответ: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                print("✅ [DeepSeek] Ключ валиден!")
                return .valid
            case 401:
                print("❌ [DeepSeek] Неверный API ключ")
                return .invalid("Неверный API ключ")
            case 403:
                print("❌ [DeepSeek] Ключ заблокирован")
                return .invalid("Ключ заблокирован")
            case 429:
                // Rate limit - но ключ валидный
                print("⚠️ [DeepSeek] Rate limit, но ключ валиден")
                return .valid
            case 500, 502, 503:
                // Проблемы сервера - сохраняем без валидации
                print("⚠️ [DeepSeek] Сервер недоступен")
                return .serverError("Сервер недоступен")
            default:
                // Пробуем получить сообщение об ошибке
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("❌ [DeepSeek] Ошибка: \(message)")
                    return .invalid(message)
                }
                print("❌ [DeepSeek] Неизвестная ошибка, код: \(httpResponse.statusCode)")
                return .serverError("Код ошибки: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ [DeepSeek] Ошибка сети: \(error.localizedDescription)")
            return .networkError("Нет подключения к сети")
        }
    }
}
