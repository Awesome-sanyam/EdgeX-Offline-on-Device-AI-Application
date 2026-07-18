<div align="center">

# 🧠 Loc.ai — Offline On-Device AI Application

**Private. Offline. Powerful.**

A fully offline, on-device AI inference app built with Flutter. Run large language models directly on your phone — no internet, no cloud, no data leaving your device.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

</div>

---

## ✨ Features

- **100% Offline Inference** — All AI processing runs locally via a native C++ llama.cpp engine (`fllama`). Zero network requests for inference.
- **Multi-Model Support** — Download and switch between 5 curated GGUF models (1.5B → 8B parameters).
- **Persistent Chat Sessions** — Full conversation history stored locally with session management.
- **PDF Document Chat** — Attach PDF files and ask questions about their content.
- **Voice Input** — Native speech-to-text for hands-free prompting.
- **Vision Screen** — AI-powered image analysis capabilities.
- **Hardware Telemetry** — Real-time RAM usage, thermal state, and GPU load monitoring.
- **Deep Hardware Profiling** — Auto-detects device CPU architecture, Neural Engine presence, and RAM to recommend optimal models.
- **Privacy-First** — No telemetry, no analytics, no cloud sync by default.
- **Glass UI** — Premium frosted-glass aesthetic with Material 3 and smooth animations.

---

## 📱 Screens

| Screen | Description |
|--------|-------------|
| **Chat** | Main conversational AI interface with PDF attachment & voice input |
| **Vision** | Image analysis using on-device multimodal models |
| **Dashboard** | Hardware telemetry, recent tasks, and system status |
| **Models Manager** | Download, manage, and switch between AI models |
| **Settings** | Privacy controls, hardware acceleration, and app configuration |

---

## 🤖 Supported AI Models

| Model | Size | RAM Required | Best For |
|-------|------|-------------|----------|
| Qwen 2.5 Fast (1.5B) | ~1.1 GB | 3.0 GB | Quick answers, daily chat |
| Gemma 2 Mobile (2B) | ~1.6 GB | 3.5 GB | Summarization, factual Q&A |
| Phi-3 Mini (3.8B) | ~2.4 GB | 4.5 GB | Balanced reasoning & coding |
| Mistral v0.3 (7B) | ~4.1 GB | 7.0 GB | Long-form writing, creativity |
| Llama-3 Standard (8B) | ~4.7 GB | 8.0 GB | Deep analysis, complex coding |

> **Note:** Models are downloaded on-demand from HuggingFace and stored locally in the app's documents directory. They are **not** included in this repository.

---

## 🏗️ Architecture

```
lib/
├── main.dart                        # App entry point + SharedPreferences init
├── core/
│   ├── ffi/
│   │   └── engine_bridge.dart       # Native C++ fllama bridge
│   ├── models/
│   │   └── ai_state.dart            # Core AI state data models
│   ├── services/
│   │   └── device_capability_service.dart  # Hardware capability detection
│   └── state/
│       ├── app_providers.dart       # All Riverpod providers (models, chat, voice, telemetry)
│       ├── ai_state_provider.dart   # AI inference state provider
│       └── chat_stream_provider.dart # Streaming chat response provider
└── ui/
    ├── app.dart                     # App root widget
    ├── core/
    │   ├── router.dart              # GoRouter navigation config
    │   ├── theme.dart               # App theme & design tokens
    │   └── widgets/                 # Shared reusable widgets
    │       ├── glass_container.dart # Frosted glass UI component
    │       ├── surface_card.dart    # Material surface card
    │       └── ai_state_badge.dart  # AI status indicator badge
    └── screens/
        ├── shell/
        │   └── app_shell.dart       # Bottom nav shell + persistent state
        ├── chat/
        │   └── chat_screen.dart     # Conversational AI chat UI
        ├── vision/
        │   └── vision_screen.dart   # Image analysis screen
        ├── dashboard/
        │   └── dashboard_screen.dart # Hardware telemetry dashboard
        ├── models/
        │   └── models_manager_screen.dart # Model download manager
        ├── document/
        │   └── document_screen.dart # Document analysis screen
        ├── tasks/
        │   └── task_screen.dart     # Task history screen
        └── settings/
            └── settings_screen.dart # App settings & privacy
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart 3.x) |
| **State Management** | Riverpod 3.x (`NotifierProvider`, `StreamProvider`) |
| **Navigation** | GoRouter 17.x (declarative, deep-link ready) |
| **AI Inference Engine** | `fllama` (llama.cpp Flutter bindings via FFI) |
| **Background Downloads** | `background_downloader` (resumable, with progress) |
| **Voice** | `speech_to_text` (native STT) |
| **PDF** | `syncfusion_flutter_pdf` (read & export) |
| **Persistence** | `shared_preferences` (chat history, settings) |
| **UI** | Material 3 + custom glass morphism design system |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.11.0` ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart SDK `^3.11.5`
- Android Studio or Xcode (for device/emulator builds)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/Awesome-sanyam/Loc.ai-Offline-on-Device-AI-Application.git
cd Loc.ai-Offline-on-Device-AI-Application

# 2. Install Flutter dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run
```

### Platform-Specific Notes

#### Android
- Minimum SDK: `API 26` (Android 8.0)
- The native `fllama` C++ library is compiled automatically during the build.
- Ensure you have NDK installed via Android Studio.

#### iOS
- Minimum iOS: `13.0`
- Run `cd ios && pod install` before first build.
- Neural Engine acceleration is auto-detected on Apple Silicon devices.

---

## ⚙️ Configuration

All app settings are persisted via `SharedPreferences` and managed through Riverpod providers:

| Setting | Provider | Key |
|---------|----------|-----|
| Selected model | `selectedModelProvider` | `selected_model` |
| NPU acceleration | `hardwareAccelerationProvider` | `npu_enabled` |
| Aggressive RAM unloading | `aggressiveRamUnloadingProvider` | `agg_ram` |
| Privacy settings | `privacySettingsProvider` | `privacy_settings` |

---

## 📁 What's NOT in This Repo

The following are intentionally excluded:

- `.gguf` model weight files (can be GBs in size — download via the app)
- Build artifacts (`/build`, `.dart_tool/`, `*.iml`)
- IDE configs (`.idea/`, `.vscode/`)
- Platform-specific generated code

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  Built with ❤️ by <a href="https://github.com/Awesome-sanyam">Sanyam</a> · Powered by <a href="https://github.com/Telosnex/fllama">fllama</a> & <a href="https://flutter.dev">Flutter</a>
</div>
