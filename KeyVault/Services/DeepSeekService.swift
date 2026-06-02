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
        case invalid(String)
        case serverError(String)
        case networkError(String)
    }
    
    /// Валидация API ключа через минимальный запрос
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
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
            return .networkError(String(localized: "Request formation error"))
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .serverError(String(localized: "Invalid server response"))
            }
            
            switch httpResponse.statusCode {
            case 200:
                return .valid
            case 401:
                return .invalid(String(localized: "Invalid API key"))
            case 403:
                return .invalid(String(localized: "Key blocked"))
            case 429:
                return .valid
            case 500, 502, 503:
                return .serverError(String(localized: "Server unavailable"))
            default:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .invalid(message)
                }
                return .serverError(String(format: String(localized: "Error code: %lld"), httpResponse.statusCode))
            }
        } catch {
            return .networkError(String(localized: "No network connection"))
        }
    }
}
