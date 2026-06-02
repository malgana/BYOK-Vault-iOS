//
//  L10n.swift
//  KeyVault
//

import Foundation

enum L10n {
    static func keysCount(_ count: Int) -> String {
        String(localized: "\(count) keys")
    }
}
