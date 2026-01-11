//
//  AddKeyView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import SwiftUI
import SwiftData

struct AddKeyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var platforms: [Platform]
    
    // Для редактирования существующего ключа
    var editingKey: APIKey?
    
    // Для предвыбранной платформы (когда добавляем из списка ключей платформы)
    var preselectedPlatform: Platform?
    
    @State private var myName: String = ""
    @State private var apiKeyValue: String = ""
    @State private var selectedPlatformName: String = ""
    @State private var customPlatformName: String = ""
    @State private var isValidating: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    private let defaultPlatforms = Platform.defaultPlatforms
    
    private var isEditMode: Bool {
        editingKey != nil
    }
    
    // Все доступные платформы: существующие + дефолтные (без дубликатов) + "New"
    private var availablePlatforms: [String] {
        let existingNames = platforms.map { $0.name }
        let allNames = Set(existingNames + defaultPlatforms)
        return Array(allNames).sorted() + ["New"]
    }
    
    private var isFormValid: Bool {
        !myName.isEmpty &&
        !apiKeyValue.isEmpty &&
        (!selectedPlatformName.isEmpty || !customPlatformName.isEmpty)
    }
    
    private var finalPlatformName: String {
        if selectedPlatformName == "New" {
            return customPlatformName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedPlatformName
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Выбор платформы
                if !isEditMode {
                    Section("Платформа") {
                        HStack {
                            Picker("Платформа", selection: $selectedPlatformName) {
                                Text("Выберите платформу").tag("")
                                ForEach(availablePlatforms, id: \.self) { platform in
                                    Text(platform).tag(platform)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                            
                            Spacer()
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                        )
                        
                        // Поле для новой платформы
                        if selectedPlatformName == "New" {
                            TextField("Название платформы", text: $customPlatformName)
                                .autocorrectionDisabled()
                        }
                    }
                } else {
                    Section("Платформа") {
                        HStack {
                            Text("Платформа")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(editingKey?.platform?.name ?? "")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                // Название ключа
                Section("Название") {
                    TextField("Мое название", text: $myName)
                        .autocorrectionDisabled()
                }
                
                // API ключ
                Section("API Ключ") {
                    HStack {
                        TextField("API ключ", text: $apiKeyValue, axis: .vertical)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(3...6)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .disabled(true)
                        
                        Button {
                            if let clipboardText = UIPasteboard.general.string {
                                apiKeyValue = clipboardText
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Кнопка сохранения
                Section {
                    Button {
                        saveKey()
                    } label: {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isEditMode ? "Сохранить изменения" : "Сохранить ключ")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid || isValidating)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditMode ? "Редактировать ключ" : "Новый ключ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private func setupInitialValues() {
        if let editingKey = editingKey {
            // Режим редактирования
            myName = editingKey.myName
            apiKeyValue = KeychainService.shared.get(for: editingKey.keychainID) ?? ""
            selectedPlatformName = editingKey.platform?.name ?? ""
        } else if let preselectedPlatform = preselectedPlatform {
            // Предвыбранная платформа
            selectedPlatformName = preselectedPlatform.name
        }
    }
    
    private func saveKey() {
        guard isFormValid else { return }
        
        isValidating = true
        
        // Небольшая задержка для UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isEditMode {
                updateExistingKey()
            } else {
                createNewKey()
            }
        }
    }
    
    private func createNewKey() {
        let platformName = finalPlatformName
        
        guard !platformName.isEmpty else {
            showError("Выберите или введите название платформы")
            return
        }
        
        // Находим или создаем платформу
        let platform: Platform
        if let existingPlatform = platforms.first(where: { $0.name == platformName }) {
            platform = existingPlatform
        } else {
            platform = Platform(name: platformName)
            modelContext.insert(platform)
        }
        
        // Создаем новый ключ
        let newKey = APIKey(myName: myName, platform: platform)
        
        // Сохраняем API ключ в Keychain
        let saved = KeychainService.shared.save(key: apiKeyValue, for: newKey.keychainID)
        
        guard saved else {
            showError("Не удалось сохранить ключ в Keychain")
            return
        }
        
        // Сохраняем в базу данных
        modelContext.insert(newKey)
        
        // TODO: Валидация ключа через API
        newKey.isValid = true
        
        isValidating = false
        dismiss()
    }
    
    private func updateExistingKey() {
        guard let editingKey = editingKey else { return }
        
        // Обновляем название
        editingKey.myName = myName
        
        // Обновляем ключ в Keychain если изменился
        let currentKey = KeychainService.shared.get(for: editingKey.keychainID) ?? ""
        if currentKey != apiKeyValue {
            let updated = KeychainService.shared.update(key: apiKeyValue, for: editingKey.keychainID)
            
            guard updated else {
                showError("Не удалось обновить ключ в Keychain")
                return
            }
            
            // Сбрасываем валидацию при изменении ключа
            editingKey.isValid = false
        }
        
        isValidating = false
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        isValidating = false
    }
}

#Preview("Добавление") {
    AddKeyView()
        .modelContainer(for: [Platform.self, APIKey.self], inMemory: true)
}

#Preview("Редактирование") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Platform.self, APIKey.self, configurations: config)
    
    let platform = Platform(name: "Anthropic")
    let key = APIKey(myName: "Рабочий ключ", platform: platform)
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key)
    
    _ = KeychainService.shared.save(key: "sk-ant-test-123", for: key.keychainID)
    
    return AddKeyView(editingKey: key)
        .modelContainer(container)
}
