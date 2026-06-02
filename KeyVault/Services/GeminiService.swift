//
//  GeminiService.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 17.01.26.
//

import Foundation

actor GeminiService {
    static let shared = GeminiService()
    
    private init() {}
    
    enum ValidationResult {
        case valid
        case invalid(String)
        case serverError(String)
        case networkError(String)
    }
    
    /// Валидация API ключа через минимальный запрос
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": "Hi"]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 1
            ]
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
            case 400:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    if message.contains("API key") {
                        return .invalid(String(localized: "Invalid API key"))
                    }
                    return .invalid(message)
                }
                return .invalid(String(localized: "Invalid request"))
            case 401, 403:
                return .invalid(String(localized: "Invalid API key"))
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
