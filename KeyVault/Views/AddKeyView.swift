//
//  AddKeyView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddKeyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var platforms: [Platform]
    @Query private var allKeys: [APIKey]
    
    // Для редактирования существующего ключа
    var editingKey: APIKey?
    
    // Для предвыбранной платформы (когда добавляем из списка ключей платформы)
    var preselectedPlatform: Platform?
    
    @State private var myName: String = ""
    @State private var apiKeyValue: String = ""
    @State private var note: String = ""
    @State private var selectedPlatformName: String = ""
    @State private var customPlatformName: String = ""
    @State private var isValidating: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var validationSuccess: Bool = false
    
    // Для загрузки иконки
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedIconData: Data?
    @State private var selectedIconImage: UIImage?
    
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
    
    private var supportsValidation: Bool {
        ["Anthropic", "DeepSeek", "Gemini", "OpenAI"].contains(finalPlatformName)
    }
    
    private var buttonText: String {
        if isEditMode {
            return "Сохранить изменения"
        }
        if validationSuccess {
            return "Ключ работает"
        }
        return supportsValidation ? "Проверить" : "Сохранить ключ"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Выбор платформы
                if !isEditMode {
                    Section {
                        Menu {
                            Picker("Платформа", selection: $selectedPlatformName) {
                                ForEach(availablePlatforms, id: \.self) { platform in
                                    if platform == "New" {
                                        Text("NEW")
                                            .foregroundStyle(.tint)
                                            .tag(platform)
                                    } else {
                                        Text(platform).tag(platform)
                                    }
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        } label: {
                            HStack {
                                Text(selectedPlatformName.isEmpty ? "Выберите платформу" : selectedPlatformName)
                                    .foregroundStyle(selectedPlatformName.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        
                        // Поле для новой платформы
                        if selectedPlatformName == "New" {
                            TextField("Название платформы", text: $customPlatformName)
                                .autocorrectionDisabled()
                        }
                    } header: {
                        Text("Платформа")
                    }
                    
                    // Загрузка иконки для новой платформы
                    if selectedPlatformName == "New" && !customPlatformName.isEmpty {
                        Section {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack {
                                    if let image = selectedIconImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.title2)
                                            .foregroundStyle(.blue)
                                            .frame(width: 50, height: 50)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedIconImage == nil ? "Добавить иконку" : "Изменить иконку")
                                            .foregroundStyle(.primary)
                                        Text("Рекомендуемый размер: 250×250px")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } header: {
                            Text("Иконка (опционально)")
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Text(editingKey?.platform?.name ?? "")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
                
                // Название ключа
                Section {
                    TextField("Название ключа", text: $myName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Название")
                }
                
                // Заметка (опционально)
                Section {
                    TextField("Добавить заметку...", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .autocorrectionDisabled()
                } header: {
                    Text("Заметка (опционально)")
                }
                
                // API ключ
                Section {
                    Button {
                        if let clipboardText = UIPasteboard.general.string {
                            apiKeyValue = clipboardText
                        }
                    } label: {
                        HStack {
                            if apiKeyValue.isEmpty {
                                Text("Нажмите чтобы вставить ключ")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(apiKeyValue)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "doc.on.clipboard")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minHeight: 60, alignment: .topLeading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Кнопка сохранения/проверки
                Section {
                    Button {
                        validateAndSave()
                    } label: {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if validationSuccess {
                                Image(systemName: "checkmark")
                            }
                            Text(buttonText)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(validationSuccess ? .white : .green)
                    }
                    .listRowBackground(validationSuccess ? Color.green : Color(uiColor: .secondarySystemGroupedBackground))
                    .disabled(!isFormValid || isValidating || validationSuccess)
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
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    await loadSelectedPhoto()
                }
            }
        .tint(.green)
        }
    }
    
    private func setupInitialValues() {
        if let editingKey = editingKey {
            // Режим редактирования
            myName = editingKey.myName
            note = editingKey.note ?? ""
            apiKeyValue = KeychainService.shared.get(for: editingKey.keychainID) ?? ""
            selectedPlatformName = editingKey.platform?.name ?? ""
        } else if let preselectedPlatform = preselectedPlatform {
            // Предвыбранная платформа
            selectedPlatformName = preselectedPlatform.name
        }
    }
    
    private func loadSelectedPhoto() async {
        guard let photoItem = selectedPhotoItem else {
            selectedIconImage = nil
            selectedIconData = nil
            return
        }
        
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Обрабатываем изображение: сжимаем до 250x250px
                if let processedData = ImageHelper.processImage(image) {
                    await MainActor.run {
                        selectedIconData = processedData
                        selectedIconImage = ImageHelper.imageFromData(processedData)
                    }
                }
            }
        } catch {
            await MainActor.run {
                showError("Не удалось загрузить изображение")
            }
        }
    }
    
    private func validateAndSave() {
        guard isFormValid else { return }
        
        // Проверка на дубликат ключа (только при создании нового)
        if !isEditMode {
            if let existingKey = findExistingKey(withValue: apiKeyValue) {
                let platformName = existingKey.platform?.name ?? "Неизвестно"
                showError("Этот ключ уже добавлен: \"\(existingKey.myName)\" (\(platformName))")
                // Очищаем поле с ключом, чтобы можно было вставить правильный
                apiKeyValue = ""
                return
            }
        }
        
        if isEditMode {
            updateExistingKey()
        } else if supportsValidation {
            // Для Anthropic — сначала валидируем
            validateAndCreateKey()
        } else {
            // Для остальных платформ — просто сохраняем
            createNewKey(isValid: false)
        }
    }
    
    private func findExistingKey(withValue value: String) -> APIKey? {
        for key in allKeys {
            if let storedValue = KeychainService.shared.get(for: key.keychainID),
               storedValue == value {
                return key
            }
        }
        return nil
    }
    
    private func validateAndCreateKey() {
        isValidating = true
        
        Task {
            // Выбираем сервис валидации в зависимости от платформы
            switch finalPlatformName {
            case "DeepSeek":
                await validateWithDeepSeek()
            case "Gemini":
                await validateWithGemini()
            case "OpenAI":
                await validateWithOpenAI()
            default:
                await validateWithAnthropic()
            }
        }
    }
    
    private func validateWithAnthropic() async {
        let result = await AnthropicService.shared.validateAPIKey(apiKeyValue)
        
        await MainActor.run {
            isValidating = false
            handleValidationResult(result)
        }
    }
    
    private func validateWithDeepSeek() async {
        let result = await DeepSeekService.shared.validateAPIKey(apiKeyValue)
        
        await MainActor.run {
            isValidating = false
            
            switch result {
            case .valid:
                handleValidationResult(.valid)
            case .invalid(let message):
                handleValidationResult(.invalid(message))
            case .serverError(let message):
                handleValidationResult(.serverError(message))
            case .networkError(let message):
                handleValidationResult(.networkError(message))
            }
        }
    }
    
    private func validateWithGemini() async {
        let result = await GeminiService.shared.validateAPIKey(apiKeyValue)
        
        await MainActor.run {
            isValidating = false
            
            switch result {
            case .valid:
                handleValidationResult(.valid)
            case .invalid(let message):
                handleValidationResult(.invalid(message))
            case .serverError(let message):
                handleValidationResult(.serverError(message))
            case .networkError(let message):
                handleValidationResult(.networkError(message))
            }
        }
    }
    
    private func validateWithOpenAI() async {
        let result = await OpenAIService.shared.validateAPIKey(apiKeyValue)
        
        await MainActor.run {
            isValidating = false
            
            switch result {
            case .valid:
                handleValidationResult(.valid)
            case .invalid(let message):
                handleValidationResult(.invalid(message))
            case .serverError(let message):
                handleValidationResult(.serverError(message))
            case .networkError(let message):
                handleValidationResult(.networkError(message))
            }
        }
    }
    
    private func handleValidationResult(_ result: AnthropicService.ValidationResult) {
        switch result {
        case .valid:
            // Показываем "Ключ работает"
            withAnimation {
                validationSuccess = true
            }
            
            // Через 1 секунду сохраняем и закрываем
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                createNewKey(isValid: true)
            }
            
        case .invalid(let message):
            showError(message)
            
        case .serverError:
            // Проблемы сервера — сохраняем без валидации
            createNewKey(isValid: false)
            
        case .networkError(let message):
            showError(message)
        }
    }
    
    private func createNewKey(isValid: Bool) {
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
            // Создаем новую платформу с иконкой (если есть)
            platform = Platform(name: platformName, customIconData: selectedIconData)
            modelContext.insert(platform)
        }
        
        // Создаем новый ключ с заметкой
        let noteValue = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let newKey = APIKey(myName: myName, platform: platform, note: noteValue.isEmpty ? nil : noteValue)
        newKey.isValid = isValid
        
        // Сохраняем API ключ в Keychain
        let saved = KeychainService.shared.save(key: apiKeyValue, for: newKey.keychainID)
        
        guard saved else {
            showError("Не удалось сохранить ключ в Keychain")
            return
        }
        
        // Сохраняем в базу данных
        modelContext.insert(newKey)
        
        // Форсируем сохранение
        try? modelContext.save()
        
        // Закрываем sheet и открываем детали
        dismiss()
    }
    
    private func updateExistingKey() {
        guard let editingKey = editingKey else { return }
        
        // Обновляем название
        editingKey.myName = myName
        
        // Обновляем заметку
        let noteValue = note.trimmingCharacters(in: .whitespacesAndNewlines)
        editingKey.note = noteValue.isEmpty ? nil : noteValue
        
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
        
        // Форсируем сохранение
        try? modelContext.save()
        
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
