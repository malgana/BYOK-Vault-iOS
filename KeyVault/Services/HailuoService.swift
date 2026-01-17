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
        // Используем тот же endpoint что и в NanoBanana - более надежный способ проверки
        let url = URL(string: "https://api.minimax.io/v1/files/retrieve?GroupId=1956997081382003480&file_id=test_invalid_id")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        print("🔄 [Hailuo] Отправляем запрос на валидацию...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [Hailuo] Неверный ответ сервера")
                return .serverError("Неверный ответ сервера")
            }
            
            print("📡 [Hailuo] HTTP статус: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [Hailuo] Ответ: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ [Hailuo] Ключ валиден!")
                return .valid
            case 400:
                // 400 для несуществующего file_id означает, что аутентификация прошла успешно
                if let responseString = String(data: data, encoding: .utf8),
                   responseString.contains("file not found") || responseString.contains("invalid") || responseString.contains("not exist") {
                    print("✅ [Hailuo] Ключ валиден! (file not found = auth OK)")
                    return .valid
                }
                // Проверяем base_resp
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let baseResp = json["base_resp"] as? [String: Any],
                   let statusCode = baseResp["status_code"] as? Int {
                    // 1004 = file not found, но авторизация прошла
                    if statusCode == 1004 || statusCode == 2013 {
                        print("✅ [Hailuo] Ключ валиден! (status_code=\(statusCode))")
                        return .valid
                    }
                }
                print("✅ [Hailuo] Ключ валиден! (400 = auth OK)")
                return .valid
            case 401:
                print("❌ [Hailuo] Неверный API ключ")
                return .invalid("Неверный API ключ")
            case 403:
                print("❌ [Hailuo] Ключ заблокирован")
                return .invalid("Ключ заблокирован")
            case 429:
                print("⚠️ [Hailuo] Rate limit, но ключ валиден")
                return .valid
            case 500, 502, 503:
                print("⚠️ [Hailuo] Сервер недоступен")
                return .serverError("Сервер недоступен")
            default:
                // Проверяем base_resp на ошибки авторизации
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let baseResp = json["base_resp"] as? [String: Any],
                   let statusCode = baseResp["status_code"] as? Int {
                    // Коды ошибок авторизации MiniMax
                    if statusCode == 1001 || statusCode == 1002 || statusCode == 2049 {
                        if let statusMsg = baseResp["status_msg"] as? String {
                            print("❌ [Hailuo] Ошибка авторизации: \(statusMsg)")
                            return .invalid(statusMsg)
                        }
                        print("❌ [Hailuo] Ошибка авторизации")
                        return .invalid("Неверный API ключ")
                    }
                }
                print("❌ [Hailuo] Неизвестная ошибка, код: \(httpResponse.statusCode)")
                return .serverError("Код ошибки: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ [Hailuo] Ошибка сети: \(error.localizedDescription)")
            return .networkError("Нет подключения к сети")
        }
    }
}
