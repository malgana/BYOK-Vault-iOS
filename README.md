# 🔐 BYOK Vault — iOS

**Bring Your Own Key** — безопасное хранилище API-ключей для iOS.

Храните API-ключи от AI-сервисов (OpenAI, Anthropic, Gemini и др.) в одном защищённом месте с использованием iOS Keychain.

---

## ✨ Возможности

- 🔒 **Безопасное хранение** — ключи хранятся в iOS Keychain
- 🏷️ **Организация по платформам** — группировка ключей по сервисам
- 🎨 **Кастомные платформы** — добавляйте свои сервисы с иконками
- 📋 **Быстрая вставка** — вставка ключа из буфера обмена в один тап
- 🔍 **Проверка дубликатов** — защита от случайного добавления одинаковых ключей
- 📝 **Заметки** — добавляйте описания к ключам
- ✅ **Валидация ключей** — проверка работоспособности API-ключей

## 🎯 Поддерживаемые платформы

Встроенные иконки для популярных AI-сервисов:

| Платформа | Иконка |
|-----------|--------|
| Anthropic | ✅ |
| OpenAI | ✅ |
| Gemini | ✅ |
| DeepSeek | ✅ |
| Hailuo | ✅ |
| Reve AI | ✅ |
| GitHub | ✅ |
| Google Image Search | ✅ |

> Можно добавить любую платформу с кастомной иконкой

---

## 🏗️ Архитектура

```
KeyVault/
├── Models/
│   ├── APIKey.swift       # SwiftData модель ключа
│   └── Platform.swift     # SwiftData модель платформы
├── Views/
│   ├── MainView.swift           # Главный экран со списком платформ
│   ├── AddKeyView.swift         # Добавление/редактирование ключа
│   ├── KeyDetailView.swift      # Детали ключа
│   ├── PlatformKeysListView.swift # Список ключей платформы
│   └── PlatformIconView.swift   # Компонент иконки платформы
├── Services/
│   ├── KeychainService.swift    # Работа с iOS Keychain
│   ├── AnthropicService.swift   # Валидация ключей Anthropic
│   └── ImageHelper.swift        # Утилиты для работы с изображениями
└── Assets.xcassets/             # Иконки платформ
```

### Безопасность

Приложение использует двухуровневую архитектуру хранения:

1. **SwiftData** — хранит только метаданные (название, платформа, дата)
2. **iOS Keychain** — хранит сами значения ключей с системным шифрованием

```swift
@Model
final class APIKey {
    var myName: String        // Название ключа
    var keychainID: String    // UUID для доступа к значению в Keychain
    var platform: Platform?
    // Сам ключ никогда не хранится в базе данных!
}
```

---

## 🛠️ Технологии

| Категория | Технология |
|-----------|------------|
| **Язык** | Swift 5.9+ |
| **UI** | SwiftUI |
| **Данные** | SwiftData |
| **Безопасность** | iOS Keychain (Security framework) |
| **Min iOS** | 17.0 |

---

## 🚀 Запуск проекта

### Требования

- Xcode 15.0+
- iOS 17.0+
- macOS Sonoma 14.0+

### Сборка

```bash
# Клонировать репозиторий
git clone https://github.com/malgana/byok-vault-ios.git

# Открыть в Xcode
open KeyVault.xcodeproj

# Собрать и запустить (⌘R)
```

---

## 📱 Скриншоты

<!-- Добавьте скриншоты приложения -->
<!-- 
<p align="center">
  <img src="screenshots/main.png" width="250" />
  <img src="screenshots/add_key.png" width="250" />
  <img src="screenshots/key_detail.png" width="250" />
</p>
-->

*Скриншоты будут добавлены позже*

---

## 📄 Лицензия

```
MIT License

Copyright (c) 2025 Aleksandr Prostetsov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🔗 Связанные проекты

- [BYOK Vault Android](https://github.com/malgana/byok-vault-android) — версия для Android (Kotlin + Jetpack Compose)

---

## 👤 Автор

**Aleksandr Prostetsov**

- GitHub: [@malgana](https://github.com/malgana)
