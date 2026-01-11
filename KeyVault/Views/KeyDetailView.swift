//
//  KeyDetailView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import SwiftUI
import SwiftData

struct KeyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var apiKey: APIKey
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showCopiedMessage = false
    
    private var apiKeyValue: String {
        KeychainService.shared.get(for: apiKey.keychainID) ?? "Ошибка загрузки ключа"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // API ключ по центру экрана
            VStack(spacing: 16) {
                Text("API Ключ")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Button {
                    copyToClipboard()
                } label: {
                    Text(apiKeyValue)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    if showCopiedMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Скопировано")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .offset(y: -50)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal)
            .frame(maxHeight: .infinity)
            
            // Статистика внизу (только для поддерживаемых платформ)
            if apiKey.platform?.supportsStatistics == true {
                VStack(spacing: 0) {
                    Divider()
                    
                    VStack(spacing: 12) {
                        Text("Статистика")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        StatisticRow(
                            icon: "dollarsign.circle.fill",
                            title: "Потрачено",
                            value: apiKey.formattedSpent,
                            color: .green
                        )
                        
                        StatisticRow(
                            icon: "number.circle.fill",
                            title: "Токены",
                            value: apiKey.formattedTokens,
                            color: .blue
                        )
                    }
                    .padding()
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(apiKey.myName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Удалить ключ", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddKeyView(editingKey: apiKey)
        }
        .alert("Удалить ключ?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                deleteKey()
            }
        } message: {
            Text("Это действие нельзя отменить. Ключ будет удален из приложения и Keychain.")
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = apiKeyValue
        
        withAnimation {
            showCopiedMessage = true
        }
        
        // Скрываем сообщение через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }
    
    private func deleteKey() {
        // Удаляем из Keychain
        _ = KeychainService.shared.delete(for: apiKey.keychainID)
        
        // Удаляем из базы данных
        modelContext.delete(apiKey)
        
        dismiss()
    }
}

// MARK: - Statistic Row
struct StatisticRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Platform.self, APIKey.self, configurations: config)
    
    let platform = Platform(name: "Anthropic")
    let key = APIKey(myName: "Рабочий ключ", platform: platform)
    key.isValid = true
    key.totalSpent = 15.30
    key.tokensUsed = 2_500_000
    key.lastStatisticsUpdate = Date()
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key)
    
    // Сохраняем тестовый ключ в Keychain
    _ = KeychainService.shared.save(key: "sk-ant-test-key-123456789", for: key.keychainID)
    
    return NavigationStack {
        KeyDetailView(apiKey: key)
            .modelContainer(container)
    }
}
