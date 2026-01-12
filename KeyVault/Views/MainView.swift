//
//  MainView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Platform.name) private var platforms: [Platform]
    @Query private var allKeys: [APIKey] // Для отслеживания изменений в ключах
    @State private var showingAddKey = false
    
    // Только платформы с ключами
    private var platformsWithKeys: [Platform] {
        platforms.filter { !$0.apiKeys.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if platformsWithKeys.isEmpty {
                    emptyStateView
                } else {
                    platformsList
                }
            }
            .navigationTitle("API Keys")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddKey = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddKey) {
                AddKeyView()
            }
            .onAppear {
                cleanupEmptyPlatforms()
            }
        }
    }
    
    // MARK: - Cleanup
    /// Удаляет пустые пользовательские платформы из базы данных
    private func cleanupEmptyPlatforms() {
        let emptyPlatforms = platforms.filter { platform in
            // Удаляем только пользовательские платформы без ключей
            !platform.isDefault && platform.apiKeys.isEmpty
        }
        
        for platform in emptyPlatforms {
            modelContext.delete(platform)
        }
        
        // Сохраняем изменения, если что-то удалили
        if !emptyPlatforms.isEmpty {
            try? modelContext.save()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Нет API ключей")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Добавьте первый ключ, нажав на +")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var platformsList: some View {
        List {
            ForEach(platformsWithKeys) { platform in
                NavigationLink {
                    destinationView(for: platform)
                } label: {
                    PlatformRow(platform: platform)
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for platform: Platform) -> some View {
        if platform.apiKeys.count == 1, let key = platform.apiKeys.first {
            KeyDetailView(apiKey: key)
        } else {
            PlatformKeysListView(platform: platform)
        }
    }
}

// MARK: - Platform Row
struct PlatformRow: View {
    let platform: Platform
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка платформы
            PlatformIconView(platform: platform, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(platform.name)
                    .font(.headline)
                
                Text("\(platform.apiKeys.count) \(keysText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var keysText: String {
        let count = platform.apiKeys.count
        if count == 1 {
            return "ключ"
        } else if count >= 2 && count <= 4 {
            return "ключа"
        } else {
            return "ключей"
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Platform.self, APIKey.self], inMemory: true)
}
