//
//  APIKey.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import Foundation
import SwiftData

@Model
final class APIKey {
    var myName: String // Пользовательское название ключа
    var keychainID: String // UUID для доступа к ключу в Keychain
    var dateAdded: Date
    var isValid: Bool
    var note: String? // Заметка к ключу
    var isAdminKey: Bool = false // Admin ключ для статистики (sk-ant-admin...)
    
    @Relationship
    var platform: Platform?
    
    var group: KeyGroup?
    
    init(myName: String, platform: Platform, note: String? = nil, isAdminKey: Bool = false, group: KeyGroup? = nil) {
        self.myName = myName
        self.platform = platform
        self.keychainID = UUID().uuidString
        self.dateAdded = Date()
        self.isValid = false
        self.note = note
        self.isAdminKey = isAdminKey
        self.group = group
    }
}
