//
//  KeyGroup.swift
//  KeyVault
//
//  Created by AI Agent on 31.01.26.
//

import Foundation
import SwiftData

@Model
final class KeyGroup {
    var name: String
    var dateCreated: Date
    
    @Relationship(deleteRule: .nullify, inverse: \APIKey.group)
    var apiKeys: [APIKey] = []
    
    @Relationship
    var platform: Platform?
    
    init(name: String, platform: Platform? = nil) {
        self.name = name
        self.platform = platform
        self.dateCreated = Date()
    }
}
