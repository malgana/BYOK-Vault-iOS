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
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var platform: Platform
    @State private var showingAddKey = false
    @State private var appearAnimation = false
    @State private var copiedKeyID: String?
    
    var body: some View {
        ZStack {
            // Градиентный фон
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(platform.apiKeys.enumerated()), id: \.element.id) { index, apiKey in
                        NavigationLink {
                            KeyDetailView(apiKey: apiKey)
                        } label: {
                            KeyGlassCard(
                                apiKey: apiKey,
                                copiedKeyID: $copiedKeyID
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.08),
                            value: appearAnimation
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(platform.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddKey = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .sheet(isPresented: $showingAddKey) {
            AddKeyView(preselectedPlatform: platform)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.05, green: 0.05, blue: 0.15),
                   Color(red: 0.1, green: 0.08, blue: 0.2),
                   Color.black]
                : [Color(red: 0.95, green: 0.95, blue: 1.0),
                   Color(red: 0.9, green: 0.92, blue: 1.0),
                   Color(red: 0.85, green: 0.88, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Key Glass Card
struct KeyGlassCard: View {
    let apiKey: APIKey
    @Binding var copiedKeyID: String?
    @Environment(\.colorScheme) private var colorScheme
    
    private var isCopied: Bool {
        copiedKeyID == apiKey.keychainID
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Индикатор статуса
            if apiKey.isAdminKey {
                // Admin ключ — иконка шестерёнки
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                    .frame(width: 12, height: 12)
            } else {
                // Обычный ключ — круглый индикатор
                Circle()
                    .fill(apiKey.isValid ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .shadow(color: apiKey.isValid ? .green.opacity(0.5) : .clear, radius: 4)
            }
            
            // Информация о ключе
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(apiKey.myName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if apiKey.isAdminKey {
                        Text("Admin")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2), in: Capsule())
                    }
                }
                
                if let note = apiKey.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Кнопка копирования
            Button {
                copyKey()
            } label: {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.title3)
                    .foregroundStyle(isCopied ? .green : .secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            glassBackground
        }
    }
    
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                .white.opacity(colorScheme == .dark ? 0.1 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.4)
                    : .black.opacity(0.1),
                radius: 12,
                x: 0,
                y: 6
            )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: apiKey.dateAdded)
    }
    
    private func copyKey() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Копируем ключ
        if let keyValue = KeychainService.shared.get(for: apiKey.keychainID) {
            UIPasteboard.general.string = keyValue
            
            withAnimation(.spring(response: 0.3)) {
                copiedKeyID = apiKey.keychainID
            }
            
            // Сбрасываем через 2 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    if copiedKeyID == apiKey.keychainID {
                        copiedKeyID = nil
                    }
                }
            }
        }
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
