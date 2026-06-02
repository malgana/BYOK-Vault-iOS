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
                return .serverError(String(localized: "Invalid server response"))
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let baseResp = json["base_resp"] as? [String: Any],
               let statusCode = baseResp["status_code"] as? Int {
                let statusMsg = baseResp["status_msg"] as? String ?? ""
                
                let isAuthError = statusMsg.lowercased().contains("login fail") ||
                                  statusMsg.lowercased().contains("invalid api") ||
                                  statusMsg.lowercased().contains("authorization") ||
                                  statusMsg.lowercased().contains("api key") ||
                                  statusMsg.lowercased().contains("api secret")
                
                if isAuthError {
                    return .invalid(String(localized: "Invalid API key"))
                }
                
                if statusCode == 1001 || statusCode == 1002 || statusCode == 2049 {
                    return .invalid(statusMsg.isEmpty ? String(localized: "Invalid API key") : statusMsg)
                }
                
                if statusCode == 0 || statusCode == 2013 {
                    return .valid
                }
                
                if statusCode == 1004 && !isAuthError {
                    return .valid
                }
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return .valid
            case 400:
                return .invalid(String(localized: "Invalid request"))
            case 401:
                return .invalid(String(localized: "Invalid API key"))
            case 403:
                return .invalid(String(localized: "Key blocked"))
            case 429:
                return .valid
            case 500, 502, 503:
                return .serverError(String(localized: "Server unavailable"))
            default:
                return .serverError(String(format: String(localized: "Error code: %lld"), httpResponse.statusCode))
            }
        } catch {
            return .networkError(String(localized: "No network connection"))
        }
    }
}
