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

    private var hasNote: Bool {
        guard let note = apiKey.note else { return false }
        return !note.isEmpty
    }

    var body: some View {
        ZStack {
            KeyVaultBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if hasNote, let note = apiKey.note {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                Spacer()

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
                        .background {
                            GlassBackground(cornerRadius: 16)
                        }
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if showCopiedMessage {
                            copiedToast
                                .offset(y: -50)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle(apiKey.myName)
        .navigationBarTitleDisplayMode(.inline)
        .keyVaultNavigationStyle()
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
                    GlassCircleButton(systemName: "ellipsis.circle")
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

    private var copiedToast: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
            Text("Скопировано")
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.green.opacity(0.85), in: Capsule())
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = apiKeyValue

        withAnimation {
            showCopiedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }

    private func deleteKey() {
        let platform = apiKey.platform
        let isLastKey = platform?.apiKeys.count == 1

        _ = KeychainService.shared.delete(for: apiKey.keychainID)
        modelContext.delete(apiKey)

        if let platform = platform, isLastKey {
            modelContext.delete(platform)
        }

        dismiss()
    }
}

#Preview("С заметкой") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Platform.self, APIKey.self, configurations: config)

    let platform = Platform(name: "Paddle")
    let key = APIKey(myName: "Client-side token", platform: platform, note: "Wow image")
    key.isValid = true

    container.mainContext.insert(platform)
    container.mainContext.insert(key)

    _ = KeychainService.shared.save(key: "test_178c92ee11d9285a0691407332d", for: key.keychainID)

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

    _ = KeychainService.shared.save(key: "sk-test-123", for: key.keychainID)

    return NavigationStack {
        KeyDetailView(apiKey: key)
            .modelContainer(container)
    }
}
