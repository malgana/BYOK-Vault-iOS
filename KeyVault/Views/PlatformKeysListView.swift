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
    @Bindable var platform: Platform
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
            VStack(alignment: .leading, spacing: 4) {
                Text(apiKey.myName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Превью заметки (если есть)
                if let note = apiKey.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
    let key1 = APIKey(myName: "Рабочий ключ", platform: platform, note: "Для работы с API в продакшене")
    key1.isValid = true
    
    let key2 = APIKey(myName: "Личный ключ", platform: platform, note: "Очень длинная заметка которая будет обрезаться в превью на одну строку с многоточием")
    key2.isValid = true
    
    let key3 = APIKey(myName: "Тестовый ключ", platform: platform)
    key3.isValid = false
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key1)
    container.mainContext.insert(key2)
    container.mainContext.insert(key3)
    
    return NavigationStack {
        PlatformKeysListView(platform: platform)
            .modelContainer(container)
    }
}
