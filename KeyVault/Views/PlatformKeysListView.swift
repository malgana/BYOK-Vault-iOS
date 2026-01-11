//
//  PlatformKeysListView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import SwiftUI
import SwiftData

struct PlatformKeysListView: View {
    @Environment(\.modelContext) private var modelContext
    let platform: Platform
    @State private var showingAddKey = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(platform.apiKeys) { apiKey in
                    NavigationLink {
                        KeyDetailView(apiKey: apiKey)
                    } label: {
                        APIKeyRow(apiKey: apiKey)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(platform.name)
        .navigationBarTitleDisplayMode(.inline)
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
            AddKeyView(preselectedPlatform: platform)
        }
    }
}

// MARK: - API Key Row
struct APIKeyRow: View {
    let apiKey: APIKey
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(apiKey.myName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Статистика если есть
                if let platform = apiKey.platform, platform.supportsStatistics {
                    HStack(spacing: 12) {
                        if let spent = apiKey.totalSpent {
                            Label(String(format: "$%.2f", spent), systemImage: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        
                        if let tokens = apiKey.tokensUsed {
                            Label(apiKey.formattedTokens, systemImage: "number.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Platform.self, APIKey.self, configurations: config)
    
    let platform = Platform(name: "Anthropic")
    let key1 = APIKey(myName: "Рабочий ключ", platform: platform)
    key1.isValid = true
    key1.totalSpent = 15.30
    key1.tokensUsed = 2_500_000
    
    let key2 = APIKey(myName: "Личный ключ", platform: platform)
    key2.isValid = true
    key2.totalSpent = 8.20
    key2.tokensUsed = 1_200_000
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key1)
    container.mainContext.insert(key2)
    
    return NavigationStack {
        PlatformKeysListView(platform: platform)
            .modelContainer(container)
    }
}
