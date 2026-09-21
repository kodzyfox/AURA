# Λ U R Λ (Aura for macOS)

<p align="center">
  <img src="native/Aura/Resources/AppIcon.png" alt="Aura Logo" width="128" height="128" />
</p>

<p align="center">
  <strong>Native Ambient Music Visualizer & Intelligent Desktop Companion for macOS</strong><br>
  <em>SwiftUI • AppKit • AVFoundation • Accelerate (vDSP FFT) • WidgetKit • CoreImage • macOS Keychain</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014.0%2B%20(Sonoma%20%7C%20Sequoia)-black?style=for-the-badge&logo=apple" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/swift-5.9%2B%20%7C%20Swift%206%20Ready-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/architecture-Universal%20(Apple%20Silicon%20%2F%20Intel)-007AFF?style=for-the-badge" alt="Architecture" />
  <img src="https://img.shields.io/badge/dependencies-0%20(100%25%20Native)-success?style=for-the-badge" alt="Dependencies: 0" />
</p>

---

### Language / Язык
- [English Documentation](#english)
- [Русская документация](#русский)

---

<a name="english"></a>
# English

## Overview

**Aura** is a lightweight, ultra-responsive, completely native music companion and ambient visualizer for macOS. Engineered without web views, Electron, or external dependencies, Aura harnesses Apple's hardware-accelerated frameworks (**Accelerate vDSP**, **Metal/CoreImage**, **AVFoundation**, and **WidgetKit**) to deliver an immersive audio-visual experience while maintaining minimal CPU and battery usage.

Whether you are listening through **Spotify**, **Apple Music**, or playing **local lossless audio files** (FLAC, WAV, AIFF, M4A, MP3), Aura seamlessly captures playback telemetry, analyzes audio frequencies, projects reactive perimeter Ambilight glow, adapts desktop wallpapers, and provides sleek desktop and menu bar interfaces.

---

## Key Features

### 1. Hardware-Accelerated Audio Reactivity (Apple Accelerate `vDSP`)
- **1024-Point Local FFT Analysis**:
  - Local playback routes through `AVAudioEngine` with a dedicated mixer tap capturing 32-bit floating-point PCM samples.
  - Applies a vectorized Hann window (`vDSP_hann_window`) to eliminate spectral leakage before computing a 1024-point Fast Fourier Transform.
  - Frequency bins are aggregated into **21 logarithmic equalizer bands** (20 Hz – 18 kHz) with instantaneous attack and smooth inertial decay.
  - Sub-bass transient detector (`kickImpact`) tracks rhythmic punch (20–250 Hz) to drive pulsation and luminous expansion.
- **Spotify Cloud Beat-Grid Synchronization**:
  - Automatically queries Spotify Audio Analysis and Audio Features APIs to fetch exact beat timestamps, bar lines, track tempo (BPM), and acoustic energy.
- **Adaptive Fallback Beat-Grid**:
  - Provides mathematical tempo interpolation for external sources without direct API metadata.
- **Transparent Signal Telemetry**:
  - Displays real-time analyzer mode: `🟢 Local FFT (1024-pt)`, `🔵 Spotify Sync`, or `🟣 Smart Beat-Grid`.

### 2. Perimeter Ambilight Edge Glow
- **Screen-Edge Dynamic Illumination**:
  - Emits an expansive neon glow along the four bezels of your Mac display.
  - Light waves travel along the screen perimeter in lockstep with the song's BPM and measure phase.
- **Intelligent Palette & Harmonic HSB Shifting**:
  - High-speed hardware-accelerated k-means clustering samples vivid artwork colors.
  - Dynamically synthesizes 4 harmonious color stops, guaranteeing deep saturation ($\ge 65\%$) and brightness ($\ge 80\%$) without desaturating or washing out into white glare.
  - Dedicated selectable presets: *Cover (Adaptive Artwork)*, *Iridescent Rainbow*, *Aurora Borealis*, *Neon Sunset*, *Amber*, *Electric Cyan*, *Neon Magenta*, *Emerald*, and *Pure White*.
- **Dock & Menu Bar Clearance**:
  - Glow geometry dynamically expands past the macOS Menu Bar (32 pt) and Dock (~80 pt) for seamless immersion.

### 3. Dynamic Multi-Monitor Wallpapers & Lock Screen
- **Live Wallpaper Engine**:
  - Generates ambient blurred desktop backgrounds from current album art via high-performance CoreImage filters.
  - **Multi-Monitor Awareness**: Independently computes and sets wallpapers scaled to the exact native resolution and aspect ratio of each connected display (`CGDirectDisplayID`).
  - **Automatic Restoration**: Memorizes original user wallpaper paths per monitor and gracefully restores them upon pausing or quitting.
  - **Lock Screen Edge Glow**: Seamlessly renders edge illumination onto the lock screen wallpaper.

### 4. Floating Desktop Overlay & Cover Modes
- **Finder-Level Desktop Canvas**:
  - Transparent borderless overlay window anchored at desktop level (`kCGDesktopWindowLevel`), positioned beneath desktop icons without obstructing window workflow.
  - Visual modes: *Vinyl Disc (Smooth 33⅓ RPM rotation)*, *Floating 3D Card*, *Minimalist*, or *Perimeter Only*.
- **Glass Mini-Player (Always-on-Top)**:
  - Compact macOS floating window featuring real-time playback control, track progress, volume, and blurred vibrancy.
- **Menu Bar Extra**:
  - Status bar item with animated audio wave icon and popover controls.
- **Fullscreen Immersive Cover (`CoverView`)**:
  - Fullscreen display with automatic cursor hiding, blurred glass backdrop, and quick `Esc` dismissal.

### 5. Notification Center Widget (`AuraWidget`)
- Standalone macOS Notification Center extension built with **WidgetKit**.
- Displays high-resolution album artwork, track information, artist metadata, and active player source directly on your lock screen and widget panel.

### 6. Last.fm 2.0 Integration & macOS Keychain
- Full Last.fm Scrobbler 2.0 compliance:
  - Secure web authentication via official auth token.
  - Immediate *Now Playing* status update upon song start.
  - Strict scrobble compliance (logged only after 50% completion or 4 minutes of playback).
  - Offline queueing with automatic flushing upon network reconnection.
  - Quick Love / Unlove track toggle.
- **Zero Insecure Storage**:
  - API keys, session tokens, and secrets are encrypted in the system **macOS Keychain** (`kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).

### 7. Performance & Energy Architecture
- **Battery & Thermal Governance**:
  - Uses `IOKit.ps` to detect power source changes; automatically dials down rendering load on battery.
  - Multi-tier frame rate throttling: 60 FPS (Plugged-in High Performance) $\to$ 30 FPS (Balanced) $\to$ 15 FPS (Battery Saver).
  - Dynamic render-scale downsampling (0.62x / 0.82x / 1.0x).
  - Screen-locked detection (`com.apple.screenIsLocked`) suspends rendering loops to conserve GPU cycles.

---

## Technical Architecture

```
native/Aura/
├── Package.swift                    # SPM manifest (macOS 14+, Swift 5.9+)
├── Info.plist                       # Bundle metadata, Apple Events usage descriptions, strict TLS
├── Aura.entitlements                # Sandboxed entitlements & AppleScript automation access
├── build.sh                         # Multi-target release builder, codesigning & DMG packager
├── Resources/                       # Icons, desert fallback art, DMG background
└── Sources/
    ├── AuraWidget/                  # macOS Notification Center Extension (WidgetKit)
    │   ├── AuraWidget.swift         # Widget timeline provider, SwiftUI layout & app group sync
    │   └── Info.plist               # Widget extension bundle manifest
    └── Aura/
        ├── App.swift                # @main entry point, NSApplicationDelegate, global hotkeys
        ├── Models.swift             # Source, Effect, Atmosphere, SavedPreset, Appearance models
        ├── Theme.swift              # Adaptive Design System tokens (Dark / Light / Accent)
        ├── MusicController.swift    # Core state coordinator & facade connecting all services
        │
        ├── LocalAudioService.swift        # AVAudioEngine player with PCM mixer tap
        ├── AudioAnalysisService.swift     # vDSP FFT 1024-point processor, Beat-Grid & BPM tracker
        ├── PlayerAutomationService.swift  # Swift Actor: async AppleScript IPC for Spotify & Apple Music
        ├── WallpaperManager.swift         # Multi-monitor CoreImage wallpaper compositor & restoration
        ├── DesktopOverlayManager.swift    # Transparent desktop window anchored at kCGDesktopWindowLevel
        ├── ColorExtractor.swift           # Hardware-accelerated k-means palette extraction & HSB booster
        ├── ArtworkFetcher.swift           # High-resolution artwork resolver (Spotify CDN, Deezer, iTunes)
        ├── LastFMService.swift            # Last.fm 2.0 API client, offline cache & MD5 signing
        ├── KeychainHelper.swift           # Secure macOS Keychain wrapper
        ├── PerformanceManager.swift       # IOKit battery telemetry, thermal throttling & FPS regulator
        ├── WindowCloseHandler.swift       # Clean window lifecycle without interrupting background audio
        │
        └── Views/
            ├── ContentView.swift          # Main dashboard, sidebar navigation & detailed settings
            ├── EdgeGlowView.swift         # Real-time Ambilight perimeter glow with BPM wave motion
            ├── AtmosphereView.swift       # Generative audio atmosphere & 21-band EQ visualizer
            ├── CoverView.swift            # Fullscreen immersive artwork stage
            ├── MiniPlayerView.swift       # Floating always-on-top glass player
            ├── MenuBarView.swift          # Menu bar extra popover view
            └── LastFMView.swift           # Last.fm account connection & session controls
```

---

## System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- **Architecture**: Universal binary (Apple Silicon M1/M2/M3/M4 & Intel x86_64)
- **Supported Players**: Spotify (Free & Premium), Apple Music, or Local Audio files (MP3, M4A, FLAC, WAV, AIFF)
- **Build Requirements**: Xcode 15+ or Xcode Command Line Tools (`swift --version` $\ge 5.9$)

---

## Building & Installation

### Option 1: Quick Release Build (Recommended)

Run the root build script:

```bash
./build.sh
```

This will automatically:
1. Compile the main application in release mode (`swift build -c release`).
2. Build the `AuraWidget.appex` Notification Center extension with `WidgetKit`.
3. Assemble the `dist/Aura.app` bundle and apply ad-hoc codesigning with proper entitlements.
4. Generate a clean distribution disk image (`dist/Aura.dmg`).

To install, simply drag `Aura.app` to your `/Applications` directory:

```bash
cp -R native/Aura/dist/Aura.app /Applications/
open /Applications/Aura.app
```

### Option 2: Swift Package Manager CLI

```bash
cd native/Aura
swift build -c release
.build/release/Aura
```

---

## Global Hotkeys & Shortcuts

| Shortcut | Action |
|:---|:---|
| `Space` | Play / Pause |
| `⌘ + Right Arrow` | Next Track |
| `⌘ + Left Arrow` | Previous Track |
| `⌘ + Up Arrow` | Increase Volume |
| `⌘ + Down Arrow` | Decrease Volume |
| `⌘ + F` | Toggle Fullscreen Cover Mode |
| `⌘ + M` | Toggle Floating Mini-Player |
| `Esc` | Exit Fullscreen Mode |

---

<a name="русский"></a>
# Русский

## Описание проекта

**Aura** — полностью нативный, легковесный и ультра-отзывчивый музыкальный компаньон и генеративный амбиентный визуализатор для macOS. Разработан без Electron, веб-обёрток и сторонних зависимостей. Aura задействует аппаратные фреймворки Apple (**Accelerate vDSP**, **Metal/CoreImage**, **AVFoundation** и **WidgetKit**), создавая глубокий аудиовизуальный эффект при минимальном потреблении ресурсов процессора и аккумулятора.

Aura поддерживает **Spotify**, **Apple Music** и **локальные аудиофайлы высокого разрешения** (FLAC, WAV, AIFF, M4A, MP3). Приложение в реальном времени синхронизирует воспроизведение, проводит спектральный анализ звука, освещает края монитора переливающимся Ambilight-свечением, адаптирует обои рабочего стола под палитру обложки и предлагает стильные виджеты для рабочего стола и строки меню.

---

## Ключевые возможности

### 1. Честная аппаратная аудио-реактивность (Apple Accelerate `vDSP`)
- **1024-точечный спектральный анализ Local FFT**:
  - При воспроизведении локальных треков декодирование происходит через `AVAudioEngine`.
  - На tap-шину микшера поступают непрерывные блоки по 1024 float PCM-семплов.
  - Векторное окно Ханна (`vDSP_hann_window`) предотвращает спектральное растекание, после чего рассчитывается быстрое преобразование Фурье (FFT).
  - Спектр разбивается на **21 логарифмическую полосу эквалайзера** (20 Гц — 18 кГц) с мгновенной реакцией на атаку и плавным затуханием.
  - Детектор кика (`kickImpact`) фиксирует всплески в диапазоне суббаса (20–250 Гц) и ритмично пульсирует свечением в такт бочке.
- **Spotify Cloud Beat-Grid Sync**:
  - При прослушивании через Spotify запрашиваются официальные данные Audio Analysis / Audio Features: точные таймкоды долей, BPM и плотность звука.
- **Адаптивный Smart Beat-Grid**:
  - Квантованная математическая сетка ритма для Apple Music и внешних источников.
- **Прозрачный статус**:
  - Под эквалайзером отображается текущий активный анализатор: `🟢 Local FFT (1024-pt)`, `🔵 Spotify Sync` или `🟣 Smart Beat-Grid`.

### 2. Рассеянное свечение по краям экрана (Ambilight Edge Glow)
- **Свечение по периметру дисплея**:
  - Охватывает все 4 границы экрана и плавно переливается в такт темпу музыки (BPM).
- **Многоцветная палитра и гармонические HSB-переливы**:
  - Аппаратно-ускоренный k-means извлекает ключевые сочные цвета из обложки альбома.
  - Алгоритм синтезирует градиент из 4 гармонических оттенков с гарантией высокой насыщенности ($\ge 65\%$) и яркости ($\ge 80\%$), исключая вымывание цвета в белесый свет.
  - Готовые пресеты: *Обложка (адаптивный)*, *Радужный спектр*, *Северное сияние*, *Неоновый закат*, *Янтарь*, *Неон циан*, *Пурпур*, *Изумруд*, *Белый*.
- **Коррекция под интерфейс macOS**:
  - Границы свечения автоматически перекрывают высоту Menu Bar (32 pt) и системного Dock (~80 pt).

### 3. Динамические обои и экран блокировки
- **Генератор размытых обоев**:
  - На основе обложки текущего трека CoreImage генерирует кинематографичные обои рабочего стола.
  - **Мультимониторность**: обои индивидуально рассчитываются под точное разрешение и соотношение сторон каждого активного дисплея (`CGDirectDisplayID`).
  - **Автоматическое восстановление**: при остановке музыки или выходе из приложения Aura бесследно возвращает оригинальные обои пользователя на всех мониторах.
  - **Свечение на экране блокировки**: Ambilight-подсветка проецируется и на экран блокировки macOS.

### 4. Оверлей рабочего стола и режимы обложки
- **Оверлей на уровне Finder**:
  - Полупрозрачный безрамочный холст, закреплённый на уровне рабочего стола (`kCGDesktopWindowLevel`) прямо под иконками Finder.
  - Стили отображения: *Виниловая пластинка (вращение 33⅓ об/мин)*, *Парящая 3D-обложка*, *Минималистичный*, *Только подсветка периметра*.
- **Плавающий стеклянный мини-плеер**:
  - Компактный плеер поверх всех окон (`.floating`, Always-on-Top) со стеклянным размытием и полным контролем трека.
- **Строка меню (Menu Bar Extra)**:
  - Иконка аудиоволны в статус-баре macOS с быстрым доступом к управлению музыкой.
- **Полноэкранный режим (`CoverView`)**:
  - Атмосферный полноэкранный просмотр с автоматическим скрытием курсора и выходом по `Esc`.

### 5. Виджет для Центра уведомлений (`AuraWidget`)
- Расширение на базе **WidgetKit**.
- Отображает крупную обложку, название трека, исполнителя и статус источника прямо на экране блокировки и в боковой панели виджетов macOS.

### 6. Интеграция с Last.fm и связка ключей macOS Keychain
- Полное соответствие официальному протоколу Last.fm 2.0:
  - Безопасная веб-авторизация по одноразовому токену.
  - Мгновенная отправка *Now Playing* в начале песни.
  - Корректный скробблинг (при прослушивании $\ge 50\%$ трека или 4 минут).
  - Офлайн-очередь с автоматической отправкой при появлении интернета.
  - Отметка трека «Любимый» (Love / Unlove).
- **Безопасность**:
  - Токены сессий и пароли шифруются в системной связке ключей **macOS Keychain** (`kSecClassGenericPassword`), исключая небезопасное хранение в открытом виде.

### 7. Архитектура энергосбережения
- **Телеметрия IOKit**:
  - Определение питания от аккумулятора и автоматическое переключение на энергосберегающие профили.
  - Динамическое ограничение частоты кадров: 60 FPS (сеть) $\to$ 30 FPS (баланс) $\to$ 15 FPS (аккумулятор).
  - При блокировке экрана (`com.apple.screenIsLocked`) циклы отрисовки останавливаются.

---

## Архитектура кодовой базы

Проект спроектирован по модульному шаблону на базе независимых сервисов и акторов (Swift Concurrency / Swift 6 Ready):
- `MusicController` — единый реактивный фасад для SwiftUI.
- `LocalAudioService` — движок воспроизведения локальных аудиофайлов на базе `AVAudioEngine`.
- `AudioAnalysisService` — аппаратный спектральный анализ через Apple Accelerate `vDSP`.
- `PlayerAutomationService` — фоновый Swift Actor с асинхронным AppleScript IPC для Spotify и Apple Music.
- `WallpaperManager` — композитинг многомониторных обоев на базе CoreImage и управление экраном блокировки.
- `DesktopOverlayManager` — прозрачный виджет на уровне рабочего стола macOS.
- `ColorExtractor` — быстрый k-means кластеризатор палитры и HSB-компенсатор насыщенности.
- `ArtworkFetcher` — многоканальный резолвер обложек высокого разрешения.
- `LastFMService` — клиент Last.fm 2.0 с MD5-подписью запросов и офлайн-очередью.
- `PerformanceManager` — мониторинг питания, термо-менеджмент и адаптивный регулятор FPS.

---

## Системные требования

- **Операционная система**: macOS 14.0 (Sonoma) или macOS 15.0+ (Sequoia)
- **Архитектура процессора**: Apple Silicon (M1/M2/M3/M4) или Intel (x86_64)
- **Поддерживаемые плееры**: Spotify (Free / Premium), Apple Music, либо локальные файлы (FLAC, MP3, M4A, WAV, AIFF)
- **Инструменты для сборки**: Xcode 15+ или Xcode Command Line Tools (`swift --version` $\ge 5.9$)

---

## Сборка и установка

### Быстрая сборка дистрибутива (Рекомендуется)

Запустите скрипт сборки в корне репозитория:

```bash
./build.sh
```

Скрипт автоматически:
1. Выполнит сборку релизного бинарного файла (`swift build -c release`).
2. Соберет расширение виджета `AuraWidget.appex` с поддержкой `WidgetKit`.
3. Упакует бандл `dist/Aura.app` с ad-hoc цифровой подписью и entitlements.
4. Создаст брендированный образ диска `dist/Aura.dmg`.

Для установки перенесите приложение в папку «Программы»:

```bash
cp -R native/Aura/dist/Aura.app /Applications/
open /Applications/Aura.app
```

---

## Горячие клавиши

| Сочетание | Действие |
|:---|:---|
| `Пробел` | Воспроизведение / Пауза |
| `⌘ + Вправо` | Следующий трек |
| `⌘ + Влево` | Предыдущий трек |
| `⌘ + Вверх` | Увеличить громкость |
| `⌘ + Вниз` | Уменьшить громкость |
| `⌘ + F` | Полноэкранный режим обложки |
| `⌘ + M` | Плавающий мини-плеер |
| `Esc` | Выход из полноэкранного режима |

---

## Лицензия / License

Distributed under the **MIT License**. Created by [Kodzy](https://github.com/kodzyfox).
