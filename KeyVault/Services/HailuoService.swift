//
//  HailuoService.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 17.01.26.
//

import Foundation

actor HailuoService {
    static let shared = HailuoService()
    
    private init() {}
    
    enum ValidationResult {
        case valid
        case invalid(String)
        case serverError(String)
        case networkError(String)
    }
    
    /// Валидация API ключа через запрос к files endpoint
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        let url = URL(string: "https://api.minimax.io/v1/files/retrieve?GroupId=1956997081382003480&file_id=test_invalid_id")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .serverError("Неверный ответ сервера")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return .valid
            case 400:
                // 400 для несуществующего file_id означает, что аутентификация прошла успешно
                if let responseString = String(data: data, encoding: .utf8),
                   responseString.contains("file not found") || responseString.contains("invalid") || responseString.contains("not exist") {
                    return .valid
                }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let baseResp = json["base_resp"] as? [String: Any],
                   let statusCode = baseResp["status_code"] as? Int {
                    if statusCode == 1004 || statusCode == 2013 {
                        return .valid
                    }
                }
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
                   let baseResp = json["base_resp"] as? [String: Any],
                   let statusCode = baseResp["status_code"] as? Int {
                    if statusCode == 1001 || statusCode == 1002 || statusCode == 2049 {
                        if let statusMsg = baseResp["status_msg"] as? String {
                            return .invalid(statusMsg)
                        }
                        return .invalid("Неверный API ключ")
                    }
                }
                return .serverError("Код ошибки: \(httpResponse.statusCode)")
            }
        } catch {
            return .networkError("Нет подключения к сети")
        }
    }
}
