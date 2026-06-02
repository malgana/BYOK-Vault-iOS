//
//  SettingsView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 17.01.26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Export Data Model
struct ExportedKey: Codable {
    let myName: String
    let platformName: String
    let keyValue: String
    let note: String?
    let isValid: Bool
    let dateAdded: Date
}

struct ExportedData: Codable {
    let version: Int
    let exportDate: Date
    let keys: [ExportedKey]
}

// MARK: - JSON Document for Export
struct KeyVaultDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var platforms: [Platform]
    @Query private var allKeys: [APIKey]
    
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDocument: KeyVaultDocument?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingImportConfirmation = false
    @State private var pendingImportData: ExportedData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                KeyVaultBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        dataSection
                        statisticsSection
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .keyVaultNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "KeyVault_Backup_\(formattedDate).json"
            ) { result in
                switch result {
                case .success:
                    showAlert(title: "Успешно", message: "Ключи экспортированы")
                case .failure(let error):
                    showAlert(title: "Ошибка", message: error.localizedDescription)
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Импорт ключей", isPresented: $showingImportConfirmation) {
                Button("Отмена", role: .cancel) {
                    pendingImportData = nil
                }
                Button("Импортировать") {
                    if let data = pendingImportData {
                        performImport(data)
                    }
                }
            } message: {
                if let data = pendingImportData {
                    Text("Будет импортировано \(data.keys.count) \(keysCountText(data.keys.count)). Существующие ключи с такими же значениями будут пропущены.")
                }
            }
        }
    }
    
    // MARK: - Sections
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Данные")

            VStack(spacing: 0) {
                Button {
                    exportKeys()
                } label: {
                    settingsActionRow(
                        icon: "square.and.arrow.up",
                        iconColor: .blue,
                        title: "Экспорт ключей",
                        subtitle: "\(allKeys.count) \(keysCountText(allKeys.count))"
                    )
                }
                .buttonStyle(CardButtonStyle())
                .disabled(allKeys.isEmpty)
                .opacity(allKeys.isEmpty ? 0.5 : 1)

                Divider()
                    .padding(.leading, 64)

                Button {
                    showingImporter = true
                } label: {
                    settingsActionRow(
                        icon: "square.and.arrow.down",
                        iconColor: .green,
                        title: "Импорт ключей",
                        subtitle: "Из JSON файла"
                    )
                }
                .buttonStyle(CardButtonStyle())
            }
            .background {
                GlassBackground(cornerRadius: 16, shadowRadius: 12, shadowY: 6)
            }

            Text("Экспорт сохраняет все ключи в зашифрованный JSON файл. Храните его в безопасном месте.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 2)
        }
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Статистика")

            VStack(spacing: 0) {
                settingsInfoRow(
                    label: "Платформ",
                    value: "\(platforms.filter { !$0.apiKeys.isEmpty }.count)"
                )

                Divider()
                    .padding(.leading, 20)

                settingsInfoRow(
                    label: "Всего ключей",
                    value: "\(allKeys.count)"
                )
            }
            .background {
                GlassBackground(cornerRadius: 16, shadowRadius: 12, shadowY: 6)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("О приложении")

            settingsInfoRow(
                label: "Версия",
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            )
            .background {
                GlassBackground(cornerRadius: 16, shadowRadius: 12, shadowY: 6)
            }
        }
    }

    // MARK: - Export
    private func exportKeys() {
        var exportedKeys: [ExportedKey] = []
        
        for key in allKeys {
            guard let keyValue = KeychainService.shared.get(for: key.keychainID) else { continue }
            
            let exportedKey = ExportedKey(
                myName: key.myName,
                platformName: key.platform?.name ?? "Unknown",
                keyValue: keyValue,
                note: key.note,
                isValid: key.isValid,
                dateAdded: key.dateAdded
            )
            exportedKeys.append(exportedKey)
        }
        
        let exportData = ExportedData(
            version: 1,
            exportDate: Date(),
            keys: exportedKeys
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)
            exportDocument = KeyVaultDocument(data: jsonData)
            showingExporter = true
        } catch {
            showAlert(title: "Ошибка", message: "Не удалось создать файл экспорта")
        }
    }
    
    // MARK: - Import
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                showAlert(title: "Ошибка", message: "Нет доступа к файлу")
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let importData = try decoder.decode(ExportedData.self, from: data)
                
                pendingImportData = importData
                showingImportConfirmation = true
            } catch {
                showAlert(title: "Ошибка", message: "Неверный формат файла")
            }
            
        case .failure(let error):
            showAlert(title: "Ошибка", message: error.localizedDescription)
        }
    }
    
    private func performImport(_ importData: ExportedData) {
        var importedCount = 0
        var skippedCount = 0
        
        // Кэш для новых платформ (чтобы не создавать дубликаты в рамках одного импорта)
        var newPlatformsCache: [String: Platform] = [:]
        
        for exportedKey in importData.keys {
            // Проверяем, нет ли уже такого ключа
            let existingKeyValue = allKeys.first { key in
                if let storedValue = KeychainService.shared.get(for: key.keychainID) {
                    return storedValue == exportedKey.keyValue
                }
                return false
            }
            
            if existingKeyValue != nil {
                skippedCount += 1
                continue
            }
            
            // Находим или создаём платформу
            let platformName = Platform.canonicalPlatformName(exportedKey.platformName)
            let platform: Platform
            if let existingPlatform = platforms.first(where: { $0.name == platformName }) {
                platform = existingPlatform
            } else if let cachedPlatform = newPlatformsCache[platformName] {
                platform = cachedPlatform
            } else {
                platform = Platform(name: platformName)
                modelContext.insert(platform)
                newPlatformsCache[platformName] = platform
            }
            
            // Создаём ключ
            let newKey = APIKey(
                myName: exportedKey.myName,
                platform: platform,
                note: exportedKey.note
            )
            newKey.isValid = exportedKey.isValid
            newKey.dateAdded = exportedKey.dateAdded // Восстанавливаем оригинальную дату
            
            // Сохраняем в Keychain
            let saved = KeychainService.shared.save(key: exportedKey.keyValue, for: newKey.keychainID)
            
            if saved {
                modelContext.insert(newKey)
                importedCount += 1
            }
        }
        
        try? modelContext.save()
        
        pendingImportData = nil
        
        var message = "Импортировано: \(importedCount)"
        if skippedCount > 0 {
            message += "\nПропущено (дубликаты): \(skippedCount)"
        }
        showAlert(title: "Импорт завершён", message: message)
    }
    
    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 4)
    }

    private func settingsActionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .shadow(color: iconColor.opacity(0.25), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func settingsInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func keysCountText(_ count: Int) -> String {
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
    SettingsView()
        .modelContainer(for: [Platform.self, APIKey.self], inMemory: true)
}
