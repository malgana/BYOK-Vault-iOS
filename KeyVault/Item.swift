//
//  Item.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 11.01.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
