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
    
    /// Валидация API ключа через запрос на генерацию видео
    func validateAPIKey(_ apiKey: String) async -> ValidationResult {
        // MiniMax/Hailuo API endpoint для генерации видео
        let url = URL(string: "https://api.minimax.chat/v1/video_generation")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Минимальный запрос для проверки ключа
        let body: [String: Any] = [
            "model": "video-01",
            "prompt": "test"
        ]
        
        print("🔄 [Hailuo] Отправляем запрос на валидацию...")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ [Hailuo] Ошибка формирования запроса: \(error)")
            return .networkError("Ошибка формирования запроса")
        }
        
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
            case 200:
                // Проверяем base_resp на ошибки даже при статусе 200
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let baseResp = json["base_resp"] as? [String: Any],
                   let statusCode = baseResp["status_code"] as? Int {
                    if statusCode == 0 {
                        print("✅ [Hailuo] Ключ валиден!")
                        return .valid
                    } else if let statusMsg = baseResp["status_msg"] as? String {
                        print("❌ [Hailuo] Ошибка: \(statusMsg)")
                        return .invalid(statusMsg)
                    }
                }
                print("✅ [Hailuo] Ключ валиден!")
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
                // Проверяем ответ на наличие ошибки
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Проверяем base_resp для MiniMax API
                    if let baseResp = json["base_resp"] as? [String: Any],
                       let statusCode = baseResp["status_code"] as? Int {
                        if statusCode == 0 || statusCode == 1004 {
                            // 0 = success, 1004 = task created
                            print("✅ [Hailuo] Ключ валиден!")
                            return .valid
                        } else if statusCode == 1001 || statusCode == 1002 {
                            // Auth errors
                            print("❌ [Hailuo] Ошибка авторизации")
                            return .invalid("Неверный API ключ")
                        } else if let statusMsg = baseResp["status_msg"] as? String {
                            print("❌ [Hailuo] Ошибка: \(statusMsg)")
                            return .invalid(statusMsg)
                        }
                    }
                    
                    // Стандартный формат ошибки
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ [Hailuo] Ошибка: \(message)")
                        return .invalid(message)
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
