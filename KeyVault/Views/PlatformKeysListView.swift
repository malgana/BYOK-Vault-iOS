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
    @State private var appearAnimation = false
    @State private var copiedKeyID: String?
    @State private var expandedGroups: Set<PersistentIdentifier> = []
    
    // Вспомогательная структура для идентификации секций
    private enum SectionItem: Hashable {
        case group(PersistentIdentifier)
        case ungrouped
    }
    
    private var sections: [SectionItem] {
        let groups = platform.groups.sorted(by: { $0.name < $1.name })
        var items = groups.map { SectionItem.group($0.id) }
        if !platform.apiKeys.filter({ $0.group == nil }).isEmpty {
            items.append(.ungrouped)
        }
        return items
    }
    
    private func keysForSection(_ section: SectionItem) -> [APIKey] {
        switch section {
        case .group(let id):
            return platform.apiKeys.filter { $0.group?.id == id }
        case .ungrouped:
            return platform.apiKeys.filter { $0.group == nil }
        }
    }
    
    var body: some View {
        ZStack {
            KeyVaultBackground()
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(sections, id: \.self) { section in
                        let keys = keysForSection(section)
                        
                        switch section {
                        case .group(let id):
                            if let group = platform.groups.first(where: { $0.id == id }) {
                                groupSection(for: group, keys: keys)
                            }
                        case .ungrouped:
                            ungroupedSection(keys: keys)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(platform.name)
        .navigationBarTitleDisplayMode(.inline)
        .keyVaultNavigationStyle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddKey = true
                } label: {
                    GlassCircleButton(systemName: "plus")
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
    
    private func deleteGroup(_ group: KeyGroup) {
        withAnimation {
            expandedGroups.remove(group.id)
            modelContext.delete(group)
            try? modelContext.save()
        }
    }
    
    @ViewBuilder
    private func groupSection(for group: KeyGroup, keys: [APIKey]) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedGroups.contains(group.id) },
                set: { isExpanded in
                    withAnimation(.snappy) {
                        if isExpanded {
                            expandedGroups.insert(group.id)
                        } else {
                            expandedGroups.remove(group.id)
                        }
                    }
                }
            )
        ) {
            VStack(spacing: 12) {
                ForEach(Array(keys.enumerated()), id: \.element.id) { index, apiKey in
                    keyRow(apiKey: apiKey, index: index)
                }
            }
            .padding(.top, 12)
        } label: {
            groupHeader(group: group, count: keys.count)
        }
        .padding(16)
        .background {
            GlassBackground(cornerRadius: 16, shadowRadius: 12, shadowY: 6)
        }
    }
    
    @ViewBuilder
    private func groupHeader(group: KeyGroup, count: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.tint)
                .font(.title3)
            
            Text(group.name)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.1), in: Capsule())
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                deleteGroup(group)
            } label: {
                Label("Удалить группу", systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    private func ungroupedSection(keys: [APIKey]) -> some View {
        VStack(spacing: 16) {
            ForEach(Array(keys.enumerated()), id: \.element.id) { index, apiKey in
                keyRow(apiKey: apiKey, index: index)
            }
        }
    }
    
    @ViewBuilder
    private func keyRow(apiKey: APIKey, index: Int) -> some View {
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

// MARK: - Key Glass Card
struct KeyGlassCard: View {
    let apiKey: APIKey
    @Binding var copiedKeyID: String?
    
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
            GlassBackground(cornerRadius: 16, shadowRadius: 12, shadowY: 6)
        }
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
