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
        ZStack(alignment: .top) {
            // API ключ по центру экрана
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("Ключ")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    if apiKey.isValid {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                
                Button {
                    copyToClipboard()
                } label: {
                    ScrollView {
                        Text(apiKeyValue)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 300)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Заметка вверху (если есть)
            if let note = apiKey.note, !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
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
        // Сохраняем ссылку на платформу и проверяем количество ключей ДО удаления
        let platform = apiKey.platform
        let isLastKey = platform?.apiKeys.count == 1
        
        // Удаляем из Keychain
        _ = KeychainService.shared.delete(for: apiKey.keychainID)
        
        // Удаляем из базы данных
        modelContext.delete(apiKey)
        
        // Если это был последний ключ платформы - удаляем и платформу
        if let platform = platform, isLastKey {
            modelContext.delete(platform)
        }
        
        dismiss()
    }
}

#Preview("С заметкой") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Platform.self, APIKey.self, configurations: config)
    
    let platform = Platform(name: "Anthropic")
    let key = APIKey(myName: "Рабочий ключ", platform: platform, note: "Мой рабочий ключ для тестирования API")
    key.isValid = true
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key)
    
    // Сохраняем тестовый ключ в Keychain
    _ = KeychainService.shared.save(key: "sk-ant-test-key-123456789", for: key.keychainID)
    
    return NavigationStack {
        KeyDetailView(apiKey: key)
            .modelContainer(container)
    }
}

#Preview("Без заметки") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Platform.self, APIKey.self, configurations: config)
    
    let platform = Platform(name: "OpenAI")
    let key = APIKey(myName: "Личный ключ", platform: platform)
    key.isValid = true
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key)
    
    // Сохраняем тестовый ключ в Keychain
    _ = KeychainService.shared.save(key: "sk-test-123", for: key.keychainID)
    
    return NavigationStack {
        KeyDetailView(apiKey: key)
            .modelContainer(container)
    }
}
