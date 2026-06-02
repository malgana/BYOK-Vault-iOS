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
    @State private var selectedGroupName: String = "No Group"
    @State private var customGroupName: String = ""
    @State private var customPlatformName: String = ""
    @State private var customDashboardURL: String = ""
    @State private var isValidating: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var validationSuccess: Bool = false
    @State private var validationFailed: Bool = false
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
        ["Claude", "DeepSeek", "Gemini", "GPT", "Hailuo"].contains(finalPlatformName)
    }
    
    private var buttonText: String {
        if isEditMode {
            return "Сохранить изменения"
        }
        if validationSuccess {
            return "Ключ работает"
        }
        if validationFailed {
            return "Сохранить ключ"
        }
        return supportsValidation ? "Проверить" : "Сохранить ключ"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                KeyVaultBackground()
                    .ignoresSafeArea()

                addKeyForm
            }
            .navigationTitle(isEditMode ? "Редактировать ключ" : "Новый ключ")
            .navigationBarTitleDisplayMode(.inline)
            .keyVaultNavigationStyle()
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
            .onChange(of: selectedPlatformName) { _, newValue in
                if newValue != "New" {
                    customDashboardURL = ""
                }
            }
            .tint(.green)
        }
    }

    private var addKeyForm: some View {
        Form {
            platformSections
            nameSection
            noteSection
            groupSection
            apiKeySection
            saveSection
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var platformSections: some View {
        if !isEditMode && preselectedPlatform == nil {
            Section {
                Menu {
                    Picker("Платформа", selection: $selectedPlatformName) {
                        ForEach(availablePlatforms, id: \.self) { platform in
                            if platform == "New" {
                                Label {
                                    Text("NEW")
                                        .foregroundStyle(.tint)
                                } icon: {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .tag(platform)
                            } else {
                                Label {
                                    Text(platform)
                                } icon: {
                                    platformPickerIcon(for: platform)
                                }
                                .tag(platform)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    HStack(spacing: 12) {
                        if !selectedPlatformName.isEmpty, selectedPlatformName != "New" {
                            platformPickerIcon(for: selectedPlatformName)
                        }
                        Text(selectedPlatformName.isEmpty ? "Выберите платформу" : selectedPlatformName)
                            .foregroundStyle(selectedPlatformName.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }

                if selectedPlatformName == "New" {
                    TextField("Название платформы", text: $customPlatformName)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Платформа")
            }
            .glassListRowBackground()

            if !selectedPlatformName.isEmpty,
               selectedPlatformName != "New",
               Platform.defaultDashboardURL(for: selectedPlatformName) != nil {
                Section {
                    DashboardLinkView(urlString: Platform.defaultDashboardURL(for: selectedPlatformName))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .glassListRowBackground()
            }

            if selectedPlatformName == "New" && !customPlatformName.isEmpty {
                Section {
                    TextField("Ссылка на личный кабинет", text: $customDashboardURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    if let dashboardURL = normalizedDashboardURL(customDashboardURL) {
                        DashboardLinkView(urlString: dashboardURL)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                } header: {
                    Text("Личный кабинет (опционально)")
                } footer: {
                    Text("Например: https://console.example.com/api-keys")
                }
                .glassListRowBackground()

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
                .glassListRowBackground()
            }
        } else if isEditMode {
            Section {
                HStack {
                    Text(editingKey?.platform?.name ?? "")
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
            .glassListRowBackground()
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Название ключа", text: $myName)
                .autocorrectionDisabled()
        } header: {
            Text("Название")
        }
        .glassListRowBackground()
    }

    private var noteSection: some View {
        Section {
            TextField("Добавить заметку...", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .autocorrectionDisabled()
        } header: {
            Text("Заметка (опционально)")
        }
        .glassListRowBackground()
    }

    private var groupSection: some View {
        Section {
            Menu {
                Picker("Группа", selection: $selectedGroupName) {
                    Text("Без группы").tag("No Group")

                    let platformGroups = platforms.first(where: { $0.name == finalPlatformName })?.groups ?? []
                    ForEach(platformGroups) { group in
                        Text(group.name).tag(group.name)
                    }

                    Divider()
                    Text("Новая группа...").tag("New Group")
                }
            } label: {
                HStack {
                    Text(selectedGroupName == "No Group" ? "Без группы" : (selectedGroupName == "New Group" ? "Новая группа" : selectedGroupName))
                        .foregroundStyle(selectedGroupName == "No Group" ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                }
            }

            if selectedGroupName == "New Group" {
                TextField("Название группы", text: $customGroupName)
                    .autocorrectionDisabled()
            }
        } header: {
            Text("Группа (опционально)")
        }
        .glassListRowBackground()
    }

    private var apiKeySection: some View {
        Section {
            Button {
                if let clipboardText = UIPasteboard.general.string {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        apiKeyValue = clipboardText
                    }
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

                    if apiKeyValue.isEmpty {
                        Image(systemName: "doc.on.clipboard")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 60, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .glassListRowBackground()
    }

    private var saveSection: some View {
        Section {
            Button {
                validateAndSave()
            } label: {
                HStack(spacing: 8) {
                    if validationSuccess {
                        Image(systemName: "checkmark")
                    }
                    Text(buttonText)
                }
                .frame(maxWidth: .infinity)
                .opacity(isValidating ? 0 : 1)
                .overlay {
                    if isValidating {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .tint(.green)
            .disabled(!isFormValid)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } footer: {
            Text(validationFailed ? "Проверка не пройдена" : " ")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func platformPickerIcon(for name: String) -> some View {
        PlatformIconView(platform: platformForPicker(name: name), size: 28)
    }

    private func platformForPicker(name: String) -> Platform {
        platforms.first(where: { $0.name == name }) ?? Platform(name: name)
    }

    private func normalizedDashboardURL(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://\(trimmed)"
    }

    private func setupInitialValues() {
        if let editingKey = editingKey {
            // Режим редактирования
            myName = editingKey.myName
            note = editingKey.note ?? ""
            apiKeyValue = KeychainService.shared.get(for: editingKey.keychainID) ?? ""
            selectedPlatformName = editingKey.platform?.name ?? ""
            selectedGroupName = editingKey.group?.name ?? "No Group"
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
        guard !isValidating && !validationSuccess else { return }
        
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
        } else if validationFailed {
            // Валидация не прошла ранее — сохраняем без валидации
            createNewKey(isValid: false)
        } else if supportsValidation {
            // Для поддерживаемых платформ — сначала валидируем
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
            case "Claude":
                await validateWithAnthropic()
            case "DeepSeek":
                await validateWithDeepSeek()
            case "Gemini":
                await validateWithGemini()
            case "GPT":
                await validateWithOpenAI()
            case "Hailuo":
                await validateWithHailuo()
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
    
    private func validateWithHailuo() async {
        let result = await HailuoService.shared.validateAPIKey(apiKeyValue)
        
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
            
        case .invalid, .serverError, .networkError:
            // Валидация не прошла — меняем кнопку на "Сохранить ключ"
            withAnimation {
                validationFailed = true
            }
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
            platform = Platform(
                name: platformName,
                customIconData: selectedIconData,
                dashboardURL: normalizedDashboardURL(customDashboardURL)
                    ?? Platform.defaultDashboardURL(for: platformName)
            )
            modelContext.insert(platform)
        }
        
        // Находим или создаем группу
        var targetGroup: KeyGroup? = nil
        if selectedGroupName == "New Group" {
            let groupName = customGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !groupName.isEmpty {
                targetGroup = KeyGroup(name: groupName, platform: platform)
                modelContext.insert(targetGroup!)
            }
        } else if selectedGroupName != "No Group" {
            targetGroup = platform.groups.first(where: { $0.name == selectedGroupName })
        }
        
        // Создаем новый ключ с заметкой
        let noteValue = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let newKey = APIKey(myName: myName, platform: platform, note: noteValue.isEmpty ? nil : noteValue, group: targetGroup)
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
        
        // Обновляем группу
        if selectedGroupName == "New Group" {
            let groupName = customGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !groupName.isEmpty {
                let newGroup = KeyGroup(name: groupName, platform: editingKey.platform)
                modelContext.insert(newGroup)
                editingKey.group = newGroup
            }
        } else if selectedGroupName == "No Group" {
            editingKey.group = nil
        } else {
            editingKey.group = editingKey.platform?.groups.first(where: { $0.name == selectedGroupName })
        }
        
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
    
    let platform = Platform(name: "Claude")
    let key = APIKey(myName: "Рабочий ключ", platform: platform)
    
    container.mainContext.insert(platform)
    container.mainContext.insert(key)
    
    _ = KeychainService.shared.save(key: "sk-ant-test-123", for: key.keychainID)
    
    return AddKeyView(editingKey: key)
        .modelContainer(container)
}
