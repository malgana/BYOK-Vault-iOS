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
            Image(systemName: platformIcon)
                .font(.title2)
                .foregroundStyle(platformColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(platform.name)
                    .font(.headline)
                
                Text("\(platform.apiKeys.count) \(keysText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Показываем общую статистику если есть
                if let totalSpent = totalSpentForPlatform {
                    Text(totalSpent)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
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
    
    private var platformColor: Color {
        switch platform.name {
        case "Anthropic": return .orange
        case "OpenAI": return .green
        case "Google AI": return .blue
        case "Hailuo": return .purple
        case "DeepSeek": return .cyan
        case "Reve AI": return .pink
        default: return .gray
        }
    }
    
    private var platformIcon: String {
        switch platform.name {
        case "Anthropic": return "brain.head.profile"
        case "OpenAI": return "sparkles"
        case "Google AI": return "g.circle.fill"
        case "Hailuo": return "waveform"
        case "DeepSeek": return "magnifyingglass.circle.fill"
        case "Reve AI": return "eye.circle.fill"
        default: return "cube.fill"
        }
    }
    
    private var totalSpentForPlatform: String? {
        let total = platform.apiKeys.compactMap { $0.totalSpent }.reduce(0, +)
        guard total > 0 else { return nil }
        return String(format: "Всего: $%.2f", total)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Platform.self, APIKey.self], inMemory: true)
}
