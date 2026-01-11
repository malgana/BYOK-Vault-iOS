//
//  KeyVaultApp.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 11.01.26.
//

import SwiftUI
import SwiftData

@main
struct KeyVaultApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Platform.self,
            APIKey.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
