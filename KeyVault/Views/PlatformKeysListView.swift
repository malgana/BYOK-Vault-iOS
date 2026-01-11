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
            Text(apiKey.myName)
                .font(.headline)
                .foregroundStyle(.primary)
            
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
    
    let key2 = APIKey(myName: "Личный ключ", platform: platform)
    key2.isValid = true
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key1)
    container.mainContext.insert(key2)
    
    return NavigationStack {
        PlatformKeysListView(platform: platform)
            .modelContainer(container)
    }
}
