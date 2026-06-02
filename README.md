# BYOK Vault — iOS

**Bring Your Own Key** — a secure API key manager for iPhone.

Store API keys for AI and developer services (OpenAI, Anthropic, Gemini, and more) in one place. Secret values live in the **iOS Keychain**; metadata stays in **SwiftData**.

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2026+-blue" alt="iOS 26+" />
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License" />
</p>

---

## Features

- **Keychain-backed secrets** — API key values never stored in SwiftData
- **Platform organization** — group keys by provider (built-in or custom)
- **Key groups** — optional folders per platform
- **Custom platforms** — add any service with your own icon (250×250 recommended)
- **One-tap paste** — insert a key from the clipboard when adding
- **Duplicate detection** — blocks saving the same key value twice
- **Notes** — optional description per key
- **Live validation** — optional check against provider APIs (Claude, GPT, Gemini, DeepSeek, Hailuo)
- **Dashboard links** — quick open to provider consoles (built-in URLs + custom)
- **Backup** — export/import vault as encrypted JSON (Settings)
- **Localization** — English and Russian (follows system language)
- **Dark UI only** — fixed dark theme with glass-style surfaces

---

## Built-in platforms

Preset icons and default dashboard URLs:

| Platform | Icon | API validation |
|----------|:----:|:----------------:|
| Claude | ✅ | ✅ |
| GPT (OpenAI) | ✅ | ✅ |
| Gemini | ✅ | ✅ |
| DeepSeek | ✅ | ✅ |
| Hailuo (MiniMax) | ✅ | ✅ |
| Grok | ✅ | — |
| Qwen | ✅ | — |
| Meta Muse-Spark | ✅ | — |
| Reve AI | ✅ | — |
| GitHub | ✅ | — |
| Google Image Search | ✅ | — |

You can add any other platform with a custom name and icon. Platform **names** are not translated (e.g. `Claude`, `GPT` stay as-is).

---

## Architecture

```
KeyVault/
├── Models/
│   ├── APIKey.swift          # SwiftData key metadata
│   ├── Platform.swift        # Provider + dashboard URL
│   └── KeyGroup.swift        # Optional groups per platform
├── Views/
│   ├── MainView.swift        # Platform grid
│   ├── PlatformKeysListView.swift
│   ├── KeyDetailView.swift
│   ├── AddKeyView.swift
│   ├── SettingsView.swift    # Export / import / stats
│   ├── DashboardLinkView.swift
│   └── PlatformIconView.swift
├── Services/
│   ├── KeychainService.swift
│   ├── AnthropicService.swift
│   ├── OpenAIService.swift
│   ├── GeminiService.swift
│   ├── DeepSeekService.swift
│   ├── HailuoService.swift
│   └── ImageHelper.swift
├── Design/
│   └── MaterialTheme.swift   # Background, glass surfaces
├── Localizable.xcstrings     # EN (source) + RU
└── Assets.xcassets/          # Platform icons
```

### Security model

Two layers:

1. **SwiftData** — names, platform, notes, validation flag, dates (no secret values)
2. **Keychain** — actual key strings, keyed by per-entry UUID

```swift
@Model
final class APIKey {
    var myName: String
    var keychainID: String    // UUID for Keychain lookup
    var platform: Platform?
    // The secret is never stored in the database.
}
```

Export JSON includes key values — treat backup files as sensitive.

---

## Tech stack

| Area | Technology |
|------|------------|
| Language | Swift 5 |
| UI | SwiftUI (iOS 26) |
| Persistence | SwiftData |
| Secrets | Security / Keychain |
| Localization | String Catalog (`Localizable.xcstrings`) |
| Min deployment | iOS 26.0 |

---

## Getting started

### Requirements

- Xcode 26+
- iOS 26+ device or simulator
- macOS compatible with Xcode 26

### Build and run

```bash
git clone https://github.com/malgana/BYOK-Vault-iOS.git
cd BYOK-Vault-iOS
open KeyVault.xcodeproj
```

Then build and run in Xcode (**⌘R**).

### Configuration

No API keys or environment variables are required to build. Your own keys are entered inside the app after install.

### For contributors

Anyone can clone and run this project in their own Xcode. There are no external dependencies (no SPM packages, no CocoaPods, no `.env` files).

**After cloning:**

1. Open `KeyVault.xcodeproj` in **Xcode 26+**.
2. Select the **KeyVault** target → **Signing & Capabilities**.
3. Enable **Automatically manage signing** and choose your **Apple ID / Development Team**.  
   The repo ships with the author's team ID — you must replace it with your own.
4. If Xcode reports a Bundle ID conflict (common on a physical device), change **Bundle Identifier** to something unique, e.g. `com.yourname.KeyVault`.
5. Choose an **iOS 26+** simulator or a connected iPhone, then press **⌘R**.

**Simulator vs device**

| Target | What you need |
|--------|----------------|
| **Simulator** | Xcode 26+ and a free Apple ID are usually enough |
| **Physical iPhone** | Apple ID required; some capabilities may need a paid [Apple Developer Program](https://developer.apple.com/programs/) membership |

**What you do not need**

- API keys or secrets to build the app
- Additional package installs or setup scripts
- Access to the author's Apple Developer account

Your API keys are entered inside the app after install — they are stored locally in the iOS Keychain on your device.

---

## Screenshots

<p align="center">
  <img src="screenshots/main.png" width="220" alt="Main screen — platform grid" />
  <img src="screenshots/platform_keys.png" width="220" alt="Keys list for a platform" />
  <img src="screenshots/add_key.png" width="220" alt="Add new key" />
</p>
<p align="center">
  <img src="screenshots/settings.png" width="220" alt="Settings — export and import" />
  <img src="screenshots/dashboard_link.png" width="220" alt="Claude console opened from in-app Dashboard link" />
</p>

*Dashboard link on the platform screen opens the provider console in Safari (example: Claude).*

---

## License

MIT — see [LICENSE](LICENSE).

Copyright (c) 2025 Aleksandr Prostetsov

---

## Author

**Aleksandr Prostetsov**

- GitHub: [@malgana](https://github.com/malgana)
