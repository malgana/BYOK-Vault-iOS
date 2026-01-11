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
    
    @Relationship
    var platform: Platform?
    
    init(myName: String, platform: Platform) {
        self.myName = myName
        self.platform = platform
        self.keychainID = UUID().uuidString
        self.dateAdded = Date()
        self.isValid = false
    }
}
