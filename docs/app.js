/**
 * Λ U R Λ — Interactive Web Application & Audio-Visual Studio
 * Real-time Canvas Shaders, Web Audio Synthesizer & Dynamic Localization
 */

(function () {
  'use strict';

  // ==========================================================================
  // Localization Dictionary (EN / RU)
  // ==========================================================================
  const translations = {
    en: {
      siteTitle: "Λ U R Λ — Native Ambient Music Visualizer for macOS",
      navOverview: "Overview",
      navSimulator: "Simulator",
      navAmbilight: "✨ Ambilight",
      navFeatures: "Features",
      navGallery: "Visualizers",
      navShortcuts: "Shortcuts",
      navInstall: "Install",
      navDownload: "Download v0.1.7",
      heroBadge: "100% Native Swift • 0 Dependencies • macOS 14+ Sonoma & Sequoia",
      heroTitle1: "Sound you can see.",
      heroTitle2: "Light you can feel.",
      heroSubtitle: "A lightweight, hardware-accelerated ambient visualizer and intelligent desktop companion crafted exclusively for Apple Silicon. Synchronizes reactive perimeter Ambilight glow, MacBook camera notch halo, and dynamic multi-monitor wallpapers.",
      btnDownloadDmg: "Download Aura.dmg",
      btnTrySimulator: "Interactive Studio",
      btnViewGithub: "Star on GitHub",
      chipSilicon: "Apple Silicon M1—M4",
      statusLive: "AURA CORE ACTIVE",
      statusSim: "HARDWARE-ACCELERATED vDSP SIMULATOR",
      shaderLabel: "SHADER:",
      glowLabel: "Glow Intensity",
      speedLabel: "Speed",
      ambWidthLabel: "Glow Width",
      btnViewportAmbilight: "Light up full screen",
      btnViewportAmbilightActive: "Exit full screen glow",
      modePulse: "Neon Pulse",
      modeGrid: "Cyber Grid",
      modeAurora: "Aurora",
      modeWaves: "Waves",
      modePrism: "Prism",
      modeSupernova: "Supernova",
      // Ambilight Section
      ambSpotlightTag: "✨ SIGNATURE FEATURE",
      ambSpotlightTitle: "Signature Perimeter Ambilight Edge Glow",
      ambSpotlightDesc: "Unlike traditional music players confined to a small window, AURA projects live neon light waves along all four borders of your display. Music literally breaks beyond the screen borders and bathes your entire workspace in soft cinematic glow.",
      ambBullet1: "<strong>Hardware k-means analysis:</strong> extracts 4 dominant colors of the album art in real-time and boosts their vibrancy using HSB color modeling.",
      ambBullet2: "<strong>Beat Impact synchronization:</strong> light pulses brightly on heavy kicks and downbeats, gracefully fading in sync with the rhythm.",
      ambBullet3: "<strong>External Displays & MacBook:</strong> harmoniously illuminates both the built-in laptop screen with Notch and external 4K/5K/Ultrawide monitors.",
      ambPaletteLabel: "Try glow palette presets:",
      ambPaletteAlbum: "🎨 Album Art",
      ambPaletteAurora: "🌌 Northern Lights",
      ambPaletteSunset: "🌅 Neon Sunset",
      ambPaletteRainbow: "🌈 Rainbow Spectrum",
      ambDemoTitle: "Ambilight Edge Glow",
      ambDemoSub: "Full perimeter display glow",
      ambDemoCaption: "← Immersive musical atmosphere without washed-out glare",
      // Metrics
      metric1Val: "0",
      metric1Lbl: "External Dependencies (100% Pure Swift)",
      metric2Val: "< 1.2%",
      metric2Lbl: "Idle CPU Usage on Apple Silicon",
      metric3Val: "1024-pt",
      metric3Lbl: "Apple Accelerate vDSP FFT Spectral Tap",
      metric4Val: "60 → 15",
      metric4Lbl: "Dynamic FPS Thermal Governance",
      // Features
      featuresTag: "PERFORMANCE & ARCHITECTURE",
      featuresTitle: "Engineered for macOS. Zero compromises.",
      featuresDesc: "No Electron. No web wrappers. No Chromium background bloat. Built directly on Apple's fastest low-level frameworks.",
      feat1Title: "Perimeter Ambilight Edge Glow",
      feat1Desc: "Projects real-time neon light waves along your display bezels. Uses hardware k-means palette extraction with HSB saturation booster to turn your display edges into an atmospheric extension of the music.",
      feat2Title: "Camera Notch Halo & Dynamic Island HUD",
      feat2Desc: "Hardware-accurate geometry hugging MacBook Pro & Air camera notches. Features expanding reactive audio wings and glanceable playback telemetry.",
      notchDemoBadge: " Hardware-Accurate Geometry",
      feat3Title: "11 Generative Visualizer Shaders",
      feat3Desc: "From retro-futuristic Cyber Grid and Neon Pulse to fluid cosmic nebulas and auroras. Fullscreen immersive artwork stage (⌘ + F) and generative audio atmosphere.",
      feat4Title: "Dynamic Multi-Monitor Wallpapers",
      feat4Desc: "CoreImage GPU wallpaper compositor generates cinematic blurred desktop and lock screen backgrounds matching the playing track, with clean 25% darkening mode and auto-restore.",
      feat5Title: "Desktop Under-Icon Overlay & Glass Mini-Player",
      feat5Desc: "Interactive borderless widget anchored at kCGDesktopWindowLevel beneath icons (spinning vinyl, floating 3D card), plus an always-on-top frosted-glass mini-player (⌘ + M).",
      feat6Title: "WidgetKit Extension & Last.fm 2.0",
      feat6Desc: "Standalone Notification Center and lock screen widgets. Official Last.fm scrobbler with offline queuing and encrypted credential storage in macOS Keychain.",
      // Gallery & Visualizers
      galleryTag: "ATMOSPHERIC PRESETS",
      galleryTitle: "11 Iconic Visualizer Modes",
      galleryDesc: "Engineered with expansive geometries and vibrant palettes that react to every beat and frequency band.",
      descNeonPulse: "Concentric neon rings with chromatic dispersion and dynamic sub-bass response.",
      descCyberGrid: "Perspective 3D horizon grid with smooth scrolling velocity and rhythm peak reactivity.",
      descAurora: "Soft shifting waves of emerald, turquoise, and violet light with harmonic modulation.",
      descWaves: "Multi-layered silky ribbons with gradient fills oscillating to the melody.",
      descPrism: "Spectral refraction through spinning multifaceted glass prisms with chromatic brilliance.",
      descSupernova: "Explosive stellar pulsar with orbital particle bursts and radial energy beams.",
      descNebula: "Smooth billowing cosmic clouds of interstellar gas with dynamic density shifts.",
      descCosmicBreath: "Gentle cosmic respiration: deep color pulsation tailored for ambient and meditative tracks.",
      descOrbit: "Rotating satellite rings orbiting the central album artwork in continuous motion.",
      descVinyl: "Tactile vinyl disc or compact disc with realistic rotation and reactive light sheens.",
      descMinimal: "Clean, understated contours with subtle breathing animations and zero visual clutter.",
      // Shortcuts
      shortcutsTag: "QUICK CONTROLS",
      shortcutsTitle: "Global Keyboard Shortcuts",
      shortcutsDesc: "Control your music and ambient atmosphere effortlessly from anywhere in macOS.",
      scPlay: "Play / Pause",
      scNext: "Next Track",
      scPrev: "Previous Track",
      scVolUp: "Increase Volume",
      scVolDown: "Decrease Volume",
      scFullscreen: "Toggle Fullscreen Cover Mode",
      scMini: "Toggle Floating Mini-Player",
      scEsc: "Exit Fullscreen Stage",
      // Install
      installTag: "GET STARTED",
      installTitle: "Ready in seconds.",
      installDesc: "Download the pre-compiled universal disk image or build directly from source in terminal.",
      tabDmg: "Pre-built DMG (Recommended)",
      tabSource: "Build from Source",
      tabReq: "System Requirements",
      dmgDownloadBtn: "⬇️ Download Aura.dmg (6.0 MB)",
      dmgStep1: "1. Download latest Aura.dmg installer from GitHub Releases.",
      dmgStep2: "2. Open the disk image and drag Aura into your Applications folder.",
      dmgStep3: "3. Launch Aura. Allow automation permissions for Spotify or Apple Music when prompted.",
      dmgTip: "Gatekeeper Tip: If macOS displays an unidentified developer prompt on first launch, right-click Aura.app → select Open, or click 'Open Anyway' in System Settings → Privacy & Security.",
      sourceClone: "# Clone repository",
      sourceBuild: "# Build native bundle & DMG",
      tabReqTitle: "macOS Architecture",
      reqOS: "<span class=\"cmd\">• Operating System:</span> macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)",
      reqArch: "<span class=\"cmd\">• Architecture:</span> Apple Silicon (M1 / M2 / M3 / M4, arm64)",
      reqPlayers: "<span class=\"cmd\">• Supported Players:</span> Spotify (Free & Premium), Apple Music, local audio files (FLAC, WAV, AIFF, M4A, MP3)",
      reqDeps: "<span class=\"cmd\">• Dependencies:</span> 0 (Pure Apple native frameworks)",
      // CTA & Footer
      ctaTitle: "Experience your music in a whole new light.",
      ctaDesc: "Download Aura v0.1.7 today. Completely native, lightweight, and engineered exclusively for Apple Silicon.",
      ctaBtn: "Download Aura for macOS",
      ctaNotes: "View Release Notes (v0.1.7)",
      ctaMeta: "macOS 14.0+ Sonoma & Sequoia • Apple Silicon (M1/M2/M3/M4) • ~6.0 MB",
      copyBtn: "Copy",
      copied: "Copied!",
      footerTagline: "Native Ambient Music Visualizer & Intelligent Desktop Companion for macOS.",
      footerCrafted: "Designed & engineered with ♥ by Kodzy.",
      footerLicense: "Proprietary License • Apple Silicon Exclusive"
    },
    ru: {
      siteTitle: "Λ U R Λ — Нативный музыкальный визуализатор для macOS",
      navOverview: "Обзор",
      navSimulator: "Симулятор",
      navAmbilight: "✨ Ambilight",
      navFeatures: "Возможности",
      navGallery: "Визуализаторы",
      navShortcuts: "Горячие клавиши",
      navInstall: "Установка",
      navDownload: "Скачать v0.1.7",
      heroBadge: "100% Native Swift • 0 Зависимостей • macOS 14+ Sonoma & Sequoia",
      heroTitle1: "Звук, который вы видите.",
      heroTitle2: "Свет, который вы чувствуете.",
      heroSubtitle: "Легковесный, аппаратно-ускоренный визуализатор музыки и настольный компаньон, созданный эксклюзивно для Apple Silicon. Динамический Ambilight по периметру экрана, ореол вокруг выреза Notch и живые обои.",
      btnDownloadDmg: "Скачать Aura.dmg",
      btnTrySimulator: "Интерактивная студия",
      btnViewGithub: "Звезда на GitHub",
      chipSilicon: "Apple Silicon M1—M4",
      statusLive: "AURA CORE АКТИВЕН",
      statusSim: "АППАРАТНЫЙ СИМУЛЯТОР vDSP",
      shaderLabel: "ШЕЙДЕР:",
      glowLabel: "Яркость",
      speedLabel: "Скорость",
      ambWidthLabel: "Ширина Ambilight",
      btnViewportAmbilight: "Зажечь весь экран",
      btnViewportAmbilightActive: "Свернуть свечение",
      modePulse: "Неоновый пульс",
      modeGrid: "Кибер-сетка",
      modeAurora: "Северное сияние",
      modeWaves: "Волны",
      modePrism: "Призма",
      modeSupernova: "Сверхновая",
      // Ambilight Section
      ambSpotlightTag: "✨ ГЛАВНАЯ ФИШКА AURA",
      ambSpotlightTitle: "Сигнатурное свечение Ambilight по бокам экрана",
      ambSpotlightDesc: "В отличие от стандартных музыкальных плееров, запертых в маленьком окне, AURA проецирует живые неоновые световые волны вдоль всех четырех границ вашего дисплея. Музыка буквально выходит за пределы экрана и заливает мягким кинематографичным светом всю рабочую зону.",
      ambBullet1: "<strong>Аппаратный k-means анализ:</strong> мгновенно считывает 4 доминантных цвета обложки альбома и усиливает их насыщенность по модели HSB.",
      ambBullet2: "<strong>Синхронизация с бочкой (Beat Impact):</strong> свет ярко вспыхивает на сильных долях и плавно угасает в такт ритму композиции.",
      ambBullet3: "<strong>Внешние мониторы и MacBook:</strong> гармонично освещает как экран ноутбука с вырезом Notch, так и внешние 4K/5K/Ultrawide дисплеи.",
      ambPaletteLabel: "Попробуйте пресеты палитры свечения:",
      ambPaletteAlbum: "🎨 Обложка альбома",
      ambPaletteAurora: "🌌 Северное сияние",
      ambPaletteSunset: "🌅 Неоновый закат",
      ambPaletteRainbow: "🌈 Радужный спектр",
      ambDemoTitle: "Ambilight Edge Glow",
      ambDemoSub: "Свечение по всему периметру дисплея",
      ambDemoCaption: "← Полное погружение в музыку без белесых засветов",
      // Metrics
      metric1Val: "0",
      metric1Lbl: "Внешних зависимостей (100% Чистый Swift)",
      metric2Val: "< 1.2%",
      metric2Lbl: "Нагрузка на CPU Apple Silicon в фоне",
      metric3Val: "1024-pt",
      metric3Lbl: "Спектральный анализ Apple Accelerate vDSP FFT",
      metric4Val: "60 → 15",
      metric4Lbl: "Адаптивное терморегулирование частоты кадров",
      // Features
      featuresTag: "ПРОИЗВОДИТЕЛЬНОСТЬ И АРХИТЕКТУРА",
      featuresTitle: "Создано для macOS. Никаких компромиссов.",
      featuresDesc: "Никакого Electron. Никаких веб-обёрток. Без фоновой нагрузки Chromium. Приложение работает напрямую с быстрейшими низкоуровневыми фреймворками Apple.",
      feat1Title: "Периметральное свечение Ambilight (Edge Glow)",
      feat1Desc: "Проецирует динамические неоновые волны по рамкам экрана в ритм трека. Аппаратный k-means анализ палитры обложки с HSB-усилителем превращает дисплей в атмосферное продолжение музыки.",
      feat2Title: "Ореол вокруг выреза Notch и Dynamic Island HUD",
      feat2Desc: "Точная геометрия для вырезов экранов MacBook Pro и Air. Пульсирующие стерео-крылья визуализатора и компактная телеметрия прямо вокруг камеры.",
      notchDemoBadge: " Аппаратная геометрия выреза",
      feat3Title: "11 генеративных шейдеров визуализации",
      feat3Desc: "От футуристичной Кибер-сетки и Неонового пульса до космических туманностей и сияний. Полноэкранный кинотеатральный режим (⌘ + F) и адаптивная атмосфера.",
      feat4Title: "Динамические обои для всех мониторов",
      feat4Desc: "Композитор CoreImage генерирует кинематографичные размытые обои под тон текущего трека с режимом 25% затемнения, автоматически восстанавливая исходные обои при паузе.",
      feat5Title: "Оверлей под иконками и стеклянный мини-плеер",
      feat5Desc: "Интерактивный виджет на уровне kCGDesktopWindowLevel прямо под иконками рабочего стола (винил, 3D-карточка), а также парящий поверх всех окон стеклянный мини-плеер (⌘ + M).",
      feat6Title: "Виджет для Центра уведомлений и Last.fm 2.0",
      feat6Desc: "Отдельное расширение WidgetKit для экрана блокировки и боковой панели. Официальный скробблинг Last.fm с офлайн-очередью и шифрованием в Связке ключей macOS.",
      // Gallery & Visualizers
      galleryTag: "АТМОСФЕРНЫЕ ПРЕСЕТЫ",
      galleryTitle: "11 культовых режимов визуализации",
      galleryDesc: "Широкоформатная геометрия и сочные градиенты, живо реагирующие на каждую долю такта и частотный диапазон.",
      descNeonPulse: "Концентрические неоновые кольца с хроматической дисперсией и динамической реакцией на бас.",
      descCyberGrid: "Перспективная 3D-сетка горизонта с плавной скоростью прокрутки и откликом на ритмические пики.",
      descAurora: "Мягкие переливающиеся волны изумрудного, бирюзового и фиолетового света с гармонической модуляцией.",
      descWaves: "Многослойные шелковистые ленты с градиентной заливкой, колеблющиеся в такт мелодии.",
      descPrism: "Преломление спектра через вращающиеся многогранные стеклянные призмы с хроматическим сиянием.",
      descSupernova: "Взрывной звёздный пульсар с орбитальными вспышками частиц и радиальными лучами энергии.",
      descNebula: "Плавные клубящиеся космические облака межзвёздного газа с динамической сменой плотности.",
      descCosmicBreath: "Мягкое дыхание Вселенной: глубинная пульсация цвета для медитативных и эмбиент-композиций.",
      descOrbit: "Вращающиеся спутниковые кольца вокруг центральной обложки альбома в непрерывном танце.",
      descVinyl: "Тактильный виниловый диск или компакт-диск с реалистичным вращением и световыми бликами.",
      descMinimal: "Чистый лаконичный контур с минималистичным дыханием без отвлекающих графических деталей.",
      // Shortcuts
      shortcutsTag: "БЫСТРОЕ УПРАВЛЕНИЕ",
      shortcutsTitle: "Глобальные горячие клавиши",
      shortcutsDesc: "Управляйте музыкой и атмосферой мгновенно из любого приложения в macOS.",
      scPlay: "Воспроизведение / Пауза",
      scNext: "Следующий трек",
      scPrev: "Предыдущий трек",
      scVolUp: "Увеличить громкость",
      scVolDown: "Уменьшить громкость",
      scFullscreen: "Полноэкранный режим с обложкой",
      scMini: "Плавающий мини-плеер",
      scEsc: "Выход из полноэкранного режима",
      // Install
      installTag: "БЫСТРЫЙ СТАРТ",
      installTitle: "Готов к работе за секунды.",
      installDesc: "Скачайте готовый установочный образ DMG или соберите напрямую из исходников в терминале.",
      tabDmg: "Готовый образ DMG (Рекомендуется)",
      tabSource: "Сборка из исходников",
      tabReq: "Системные требования",
      dmgDownloadBtn: "⬇️ Скачать Aura.dmg (6.0 MB)",
      dmgStep1: "1. Скачайте образ Aura.dmg со страницы релизов GitHub.",
      dmgStep2: "2. Откройте образ и перетащите Aura в папку «Программы» (Applications).",
      dmgStep3: "3. Запустите Aura и подтвердите доступ к автоматизации Spotify или Apple Music.",
      dmgTip: "Совет Gatekeeper: при первом запуске нажмите правой кнопкой мыши по Aura.app → «Открыть» или выберите «Подтвердить вход» в Системных настройках → Конфиденциальность и безопасность.",
      sourceClone: "# Клонирование репозитория",
      sourceBuild: "# Сборка нативного бандла и DMG",
      tabReqTitle: "Архитектура macOS",
      reqOS: "<span class=\"cmd\">• Операционная система:</span> macOS 14.0 (Sonoma) или macOS 15.0+ (Sequoia)",
      reqArch: "<span class=\"cmd\">• Архитектура:</span> Apple Silicon (M1 / M2 / M3 / M4, arm64)",
      reqPlayers: "<span class=\"cmd\">• Поддерживаемые плееры:</span> Spotify (Free & Premium), Apple Music, локальные аудиофайлы (FLAC, WAV, AIFF, M4A, MP3)",
      reqDeps: "<span class=\"cmd\">• Зависимости:</span> 0 (Чистые нативные фреймворки Apple)",
      // CTA & Footer
      ctaTitle: "Взгляните на свою музыку по-новому.",
      ctaDesc: "Скачайте Aura v0.1.7 прямо сейчас. Полностью нативно, сверхлегковесно и эксклюзивно для Apple Silicon.",
      ctaBtn: "Скачать Aura для macOS",
      ctaNotes: "Список изменений (v0.1.7)",
      ctaMeta: "macOS 14.0+ Sonoma & Sequoia • Apple Silicon (M1/M2/M3/M4) • ~6.0 MB",
      copyBtn: "Копировать",
      copied: "Скопировано!",
      footerTagline: "Нативный музыкальный визуализатор и умный настольный компаньон для macOS.",
      footerCrafted: "Разработано с душой Kodzy.",
      footerLicense: "Проприетарная лицензия • Эксклюзивно для Apple Silicon"
    }
  };

  let currentLang = 'ru';

  function initLanguage() {
    const saved = localStorage.getItem('aura_lang');
    if (saved && (saved === 'ru' || saved === 'en')) {
      currentLang = saved;
    } else {
      const userLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
      currentLang = (userLang.startsWith('ru') || userLang.startsWith('be') || userLang.startsWith('uk') || userLang.startsWith('kk')) ? 'ru' : 'en';
    }
    applyLanguage(currentLang);
  }

  function applyLanguage(lang) {
    currentLang = lang;
    localStorage.setItem('aura_lang', lang);
    const dict = translations[lang] || translations.en;

    document.documentElement.lang = lang;
    if (dict.siteTitle) {
      document.title = dict.siteTitle;
    }

    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (dict[key]) {
        if (dict[key].includes('<') && dict[key].includes('>')) {
          el.innerHTML = dict[key];
        } else {
          el.textContent = dict[key];
        }
      }
    });

    const langBtn = document.getElementById('langToggle');
    if (langBtn) {
      langBtn.innerHTML = `<span>🌐</span> <span>${lang.toUpperCase()}</span>`;
    }

    const vpSpan = document.querySelector('#viewportAmbilightBtn span:last-child');
    if (vpSpan) {
      vpSpan.textContent = isViewportAmbilightActive ? dict.btnViewportAmbilightActive : dict.btnViewportAmbilight;
    }
  }

  window.toggleLanguage = function () {
    const next = currentLang === 'ru' ? 'en' : 'ru';
    applyLanguage(next);
  };

  // ==========================================================================
  // Simulated Music Library & Playback State
  // ==========================================================================
  const demoTracks = [
    {
      title: "Resonance Horizon",
      artist: "Aura Ambient Soundlab",
      duration: 215,
      cover: "assets/aura_cover.jpg",
      primaryColor: "#00f2fe",
      secondaryColor: "#8a2be2",
      edgeGlow: "radial-gradient(circle at 50% 50%, rgba(0, 242, 254, 0.5), rgba(138, 43, 226, 0.4), transparent 75%)"
    },
    {
      title: "Neon Cybernetic Pulse",
      artist: "Kodzy • Silicon Drive",
      duration: 184,
      cover: "assets/AppIcon.png",
      primaryColor: "#ff007a",
      secondaryColor: "#00f2fe",
      edgeGlow: "radial-gradient(circle at 50% 50%, rgba(255, 0, 122, 0.5), rgba(0, 242, 254, 0.4), transparent 75%)"
    },
    {
      title: "Solar Stellar Winds",
      artist: "Accelerate Synth Orchestra",
      duration: 242,
      cover: "assets/dmg_background.png",
      primaryColor: "#ffaa00",
      secondaryColor: "#ff007a",
      edgeGlow: "radial-gradient(circle at 50% 50%, rgba(255, 170, 0, 0.5), rgba(255, 0, 122, 0.4), transparent 75%)"
    }
  ];

  let currentTrackIndex = 0;
  let isPlaying = true;
  let currentTimeSec = 45;
  let visualizerMode = 'neonPulse';
  let glowIntensity = 1.3;
  let speedMultiplier = 1.0;
  let edgeThickness = 65;
  let currentPaletteMode = 'album';
  let isViewportAmbilightActive = false;
  let audioContext = null;
  let synthGain = null;
  let isAudioMuted = true;

  const ambilightPalettes = {
    album: [
      { c1: '#00f2fe', c2: '#8a2be2', c3: '#ff007a', c4: '#00f0a8' },
      { c1: '#ff007a', c2: '#00f2fe', c3: '#8a2be2', c4: '#ffaa00' },
      { c1: '#ffaa00', c2: '#ff007a', c3: '#00f2fe', c4: '#8a2be2' }
    ],
    aurora: { c1: '#0de699', c2: '#00bfe6', c3: '#7333d9', c4: '#00f0a8' },
    sunset: { c1: '#ff007a', c2: '#ffaa00', c3: '#8a2be2', c4: '#ff5722' },
    rainbow: { c1: '#ff0055', c2: '#ffcc00', c3: '#00f2fe', c4: '#b300ff' }
  };

  function formatTime(seconds) {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  }

  function updatePlayerHUD() {
    const track = demoTracks[currentTrackIndex];
    const titleEl = document.getElementById('hudSongTitle');
    const artistEl = document.getElementById('hudSongArtist');
    const coverEl = document.getElementById('hudAlbumCover');
    const currentPosEl = document.getElementById('hudCurrentPos');
    const durationEl = document.getElementById('hudDuration');
    const progressFill = document.getElementById('hudProgressFill');
    const playBtn = document.getElementById('playPauseBtn');

    if (titleEl) titleEl.textContent = track.title;
    if (artistEl) artistEl.textContent = track.artist;
    if (coverEl) coverEl.src = track.cover;
    if (currentPosEl) currentPosEl.textContent = formatTime(currentTimeSec);
    if (durationEl) durationEl.textContent = formatTime(track.duration);

    if (progressFill) {
      const pct = (currentTimeSec / track.duration) * 100;
      progressFill.style.width = `${pct}%`;
    }

    // Resolve active 4-color Ambilight palette
    let palette;
    if (currentPaletteMode === 'album') {
      palette = ambilightPalettes.album[currentTrackIndex % ambilightPalettes.album.length];
    } else {
      palette = ambilightPalettes[currentPaletteMode] || ambilightPalettes.album[0];
    }

    // Set CSS Custom Properties for live 4-sided Ambilight
    const root = document.documentElement;
    root.style.setProperty('--amb-col-1', palette.c1);
    root.style.setProperty('--amb-col-2', palette.c2);
    root.style.setProperty('--amb-col-3', palette.c3);
    root.style.setProperty('--amb-col-4', palette.c4);
    root.style.setProperty('--edge-thickness', `${edgeThickness}px`);
    root.style.setProperty('--amb-opacity', `${Math.min(1.0, glowIntensity * (isPlaying ? 0.95 : 0.35))}`);

    // Update outer glow wings and background reflections
    const wingL = document.querySelector('.wing-left');
    const wingR = document.querySelector('.wing-right');
    const glowTop = document.querySelector('.outer-glow-top');
    const glowDesk = document.querySelector('.outer-glow-desk');
    const spotlightDemoGlow = document.getElementById('spotlightDemoGlow');

    if (wingL) {
      wingL.style.background = `radial-gradient(ellipse at center, ${palette.c1} 0%, ${palette.c2} 55%, transparent 80%)`;
      wingL.style.opacity = isPlaying ? `${Math.min(1.0, 0.85 * glowIntensity)}` : '0.2';
    }
    if (wingR) {
      wingR.style.background = `radial-gradient(ellipse at center, ${palette.c3} 0%, ${palette.c1} 55%, transparent 80%)`;
      wingR.style.opacity = isPlaying ? `${Math.min(1.0, 0.85 * glowIntensity)}` : '0.2';
    }
    if (glowTop) {
      glowTop.style.background = `radial-gradient(ellipse at center, ${palette.c1} 0%, ${palette.c2} 60%, transparent 80%)`;
      glowTop.style.opacity = isPlaying ? `${Math.min(1.0, 0.7 * glowIntensity)}` : '0.15';
    }
    if (glowDesk) {
      glowDesk.style.background = `radial-gradient(ellipse at center, ${palette.c3} 0%, ${palette.c1} 45%, transparent 75%)`;
      glowDesk.style.opacity = isPlaying ? `${Math.min(1.0, 0.75 * glowIntensity)}` : '0.2';
    }
    if (spotlightDemoGlow) {
      spotlightDemoGlow.style.boxShadow = `inset 0 0 60px ${palette.c1}, inset 0 0 120px ${palette.c2}, 0 0 45px ${palette.c1}`;
    }

    if (playBtn) {
      playBtn.innerHTML = isPlaying
        ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>`
        : `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>`;
    }
  }

  // ==========================================================================
  // Web Audio Ambient Synthesizer (Zero-download ambient soundscape)
  // ==========================================================================
  function initWebAudio() {
    if (audioContext) return;
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      audioContext = new AudioCtx();

      synthGain = audioContext.createGain();
      synthGain.gain.setValueAtTime(isAudioMuted ? 0 : 0.08, audioContext.currentTime);

      const filter = audioContext.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(650, audioContext.currentTime);

      synthGain.connect(filter);
      filter.connect(audioContext.destination);

      // Warm ambient chord progression
      const chords = [
        [174.61, 220.00, 261.63, 329.63], // Fmaj7
        [196.00, 246.94, 293.66, 392.00], // G
        [164.81, 196.00, 246.94, 293.66], // Em7
        [220.00, 261.63, 329.63, 392.00]  // Am7
      ];

      let chordIdx = 0;
      function playChord() {
        if (!audioContext || audioContext.state === 'suspended') return;
        const now = audioContext.currentTime;
        const notes = chords[chordIdx % chords.length];
        chordIdx++;

        notes.forEach((freq) => {
          const osc = audioContext.createOscillator();
          const noteGain = audioContext.createGain();

          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now);

          noteGain.gain.setValueAtTime(0.001, now);
          noteGain.gain.exponentialRampToValueAtTime(0.04, now + 1.2);
          noteGain.gain.exponentialRampToValueAtTime(0.001, now + 4.8);

          osc.connect(noteGain);
          noteGain.connect(synthGain);

          osc.start(now);
          osc.stop(now + 5.0);
        });
      }

      setInterval(() => {
        if (isPlaying && !isAudioMuted) {
          playChord();
        }
      }, 4200);

      playChord();
    } catch (e) {
      console.warn("Web Audio not supported or blocked:", e);
    }
  }

  // ==========================================================================
  // Real-time Visualizer Canvas Engine
  // ==========================================================================
  class VisualizerEngine {
    constructor(canvasId) {
      this.canvas = document.getElementById(canvasId);
      if (!this.canvas) return;
      this.ctx = this.canvas.getContext('2d');
      this.time = 0;
      this.particles = [];
      this.resize();
      this.initParticles();

      window.addEventListener('resize', () => this.resize());
      this.animate = this.animate.bind(this);
      requestAnimationFrame(this.animate);
    }

    resize() {
      const rect = this.canvas.getBoundingClientRect();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      this.width = rect.width;
      this.height = rect.height;
      this.canvas.width = this.width * dpr;
      this.canvas.height = this.height * dpr;
      this.ctx.scale(dpr, dpr);
    }

    initParticles() {
      this.particles = [];
      for (let i = 0; i < 48; i++) {
        this.particles.push({
          x: Math.random() * (this.width || 800),
          y: Math.random() * (this.height || 500),
          radius: Math.random() * 2.5 + 1,
          speedX: (Math.random() - 0.5) * 0.8,
          speedY: (Math.random() - 0.5) * 0.8,
          alpha: Math.random() * 0.6 + 0.2
        });
      }
    }

    animate() {
      // Pause if tab is hidden to save power (battery friendly rule)
      if (document.hidden) {
        requestAnimationFrame(this.animate);
        return;
      }

      if (isPlaying) {
        this.time += 0.025 * speedMultiplier;
        currentTimeSec = (currentTimeSec + 0.016) % demoTracks[currentTrackIndex].duration;
      }

      this.ctx.clearRect(0, 0, this.width, this.height);
      const track = demoTracks[currentTrackIndex];

      // Dispatch to active visualizer shader
      switch (visualizerMode) {
        case 'neonPulse':
          this.renderNeonPulse(track);
          break;
        case 'cyberGrid':
          this.renderCyberGrid(track);
          break;
        case 'aurora':
          this.renderAurora(track);
          break;
        case 'waves':
          this.renderWaves(track);
          break;
        case 'prism':
          this.renderPrism(track);
          break;
        case 'supernova':
          this.renderSupernova(track);
          break;
        default:
          this.renderNeonPulse(track);
      }

      this.renderParticles();
      this.updateNotchWings();

      // Real-time audio reactive kick pulse for Ambilight Edge Glow (matching EdgeGlowView.swift beat impact)
      if (isPlaying) {
        const beatVal = Math.sin(this.time * 2.8) * 0.5 + 0.5;
        const kickPulse = Math.pow(beatVal, 3);
        const dynamicThickness = Math.round(edgeThickness + kickPulse * 22);
        document.documentElement.style.setProperty('--edge-thickness', `${dynamicThickness}px`);

        const wingL = document.querySelector('.wing-left');
        const wingR = document.querySelector('.wing-right');
        if (wingL && wingR) {
          const s = (1.0 + kickPulse * 0.22) * (glowIntensity * 0.9);
          wingL.style.transform = `scale(${s})`;
          wingR.style.transform = `scale(${s})`;
        }
      }

      requestAnimationFrame(this.animate);
    }

    updateNotchWings() {
      const wings = document.querySelectorAll('.notch-wing-bar');
      if (!wings.length) return;
      const beat = isPlaying ? Math.abs(Math.sin(this.time * 2.8)) : 0.15;
      wings.forEach((bar, idx) => {
        const offset = Math.sin(this.time * 3 + idx * 0.7);
        const h = Math.max(3, Math.min(14, (beat * 8 + offset * 4 + 4)));
        bar.style.height = `${h}px`;
      });
    }

    renderParticles() {
      this.ctx.save();
      this.particles.forEach(p => {
        if (isPlaying) {
          p.x += p.speedX * speedMultiplier;
          p.y += p.speedY * speedMultiplier;
          if (p.x < 0) p.x = this.width;
          if (p.x > this.width) p.x = 0;
          if (p.y < 0) p.y = this.height;
          if (p.y > this.height) p.y = 0;
        }
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = `rgba(255, 255, 255, ${p.alpha * 0.4})`;
        this.ctx.fill();
      });
      this.ctx.restore();
    }

    // Dynamically calculate the EXACT pixel center of the album cover card
    getCenter() {
      const coverCard = document.querySelector('.album-cover-card') || document.getElementById('hudAlbumCover');
      if (coverCard && this.canvas) {
        const canvasRect = this.canvas.getBoundingClientRect();
        const coverRect = coverCard.getBoundingClientRect();
        if (canvasRect.width > 0 && coverRect.width > 0) {
          const cx = (coverRect.left + coverRect.width / 2) - canvasRect.left;
          const cy = (coverRect.top + coverRect.height / 2) - canvasRect.top;
          return { cx, cy };
        }
      }
      return { cx: this.width / 2, cy: this.height * 0.46 };
    }

    // 1. Neon Pulse (tactical rounded concentric pulses centered directly on the album cover)
    renderNeonPulse(track) {
      const { cx, cy } = this.getCenter();
      const beat = isPlaying ? Math.sin(this.time * 2.5) * 0.35 + 0.65 : 0.4;
      const rings = 4;
      const baseRadius = 64; // Starts right outside the 110px album cover square (half-width 55px)

      this.ctx.save();
      for (let i = 1; i <= rings; i++) {
        const r = baseRadius + (i * 32 + (this.time * 22 * i) % 115) * beat;
        this.ctx.beginPath();
        if (this.ctx.roundRect) {
          // Native Aura style rounded tactical rectangle matching album cover corner radius
          const size = r * 1.85;
          this.ctx.roundRect(cx - size / 2, cy - size / 2, size, size, 20);
        } else {
          this.ctx.arc(cx, cy, r, 0, Math.PI * 2);
        }
        this.ctx.lineWidth = Math.max(1.4, 4.2 - i * 0.75) * glowIntensity;
        this.ctx.strokeStyle = i % 2 === 0 ? track.primaryColor : track.secondaryColor;
        this.ctx.shadowColor = track.primaryColor;
        this.ctx.shadowBlur = 18 * glowIntensity;
        this.ctx.stroke();
      }
      this.ctx.restore();
    }

    // 2. Cyber Grid (vanishing horizon aligns directly with bottom edge of album cover)
    renderCyberGrid(track) {
      const { cx, cy } = this.getCenter();
      const horizonY = cy + 62;
      this.ctx.save();
      this.ctx.strokeStyle = track.primaryColor;
      this.ctx.lineWidth = 1;
      this.ctx.shadowColor = track.primaryColor;
      this.ctx.shadowBlur = 8 * glowIntensity;

      // Perspective vertical lines converging on cover center
      const lineCount = 14;
      for (let i = -lineCount; i <= lineCount; i++) {
        const bottomX = cx + (i * this.width) / lineCount;
        this.ctx.beginPath();
        this.ctx.moveTo(cx, horizonY);
        this.ctx.lineTo(bottomX, this.height);
        this.ctx.stroke();
      }

      // Rolling horizontal lines
      const numHoriz = 9;
      for (let j = 0; j < numHoriz; j++) {
        const offset = ((this.time * 0.8 + j / numHoriz) % 1);
        const y = horizonY + Math.pow(offset, 2.2) * (this.height - horizonY);
        this.ctx.beginPath();
        this.ctx.moveTo(0, y);
        this.ctx.lineTo(this.width, y);
        this.ctx.stroke();
      }
      this.ctx.restore();
    }

    // 3. Aurora (curtains of light flowing centered around cover Y)
    renderAurora(track) {
      const { cx, cy } = this.getCenter();
      const bands = 3;
      this.ctx.save();
      for (let b = 0; b < bands; b++) {
        this.ctx.beginPath();
        this.ctx.moveTo(0, this.height);
        for (let x = 0; x <= this.width; x += 15) {
          const y = cy +
            Math.sin(x * 0.008 + this.time * 1.5 + b) * 35 +
            Math.cos(x * 0.015 - this.time * 0.8) * 20;
          this.ctx.lineTo(x, y);
        }
        this.ctx.lineTo(this.width, this.height);
        this.ctx.closePath();

        const grad = this.ctx.createLinearGradient(0, cy - 80, 0, this.height);
        grad.addColorStop(0, b === 0 ? 'rgba(0, 240, 168, 0.35)' : 'rgba(0, 242, 254, 0.25)');
        grad.addColorStop(1, 'rgba(138, 43, 226, 0.0)');
        this.ctx.fillStyle = grad;
        this.ctx.fill();
      }
      this.ctx.restore();
    }

    // 4. Waves (fluid harmonic ribbons passing directly through cover center)
    renderWaves(track) {
      const { cx, cy } = this.getCenter();
      this.ctx.save();
      for (let w = 0; w < 3; w++) {
        this.ctx.beginPath();
        for (let x = 0; x <= this.width; x += 10) {
          const y = cy + Math.sin(x * 0.012 + this.time * 2 + w * 1.2) * (26 + w * 8);
          if (x === 0) this.ctx.moveTo(x, y);
          else this.ctx.lineTo(x, y);
        }
        this.ctx.strokeStyle = w === 0 ? track.primaryColor : track.secondaryColor;
        this.ctx.lineWidth = (2.5 - w * 0.6) * glowIntensity;
        this.ctx.shadowColor = track.primaryColor;
        this.ctx.shadowBlur = 12 * glowIntensity;
        this.ctx.stroke();
      }
      this.ctx.restore();
    }

    // 5. Prism (polygonal refractive spectrum rotating around album cover center)
    renderPrism(track) {
      const { cx, cy } = this.getCenter();
      this.ctx.save();
      this.ctx.translate(cx, cy);
      this.ctx.rotate(this.time * 0.4);

      const sides = 6;
      const radius = 82 + Math.sin(this.time * 2.2) * 14;
      this.ctx.beginPath();
      for (let i = 0; i < sides; i++) {
        const a = (i * 2 * Math.PI) / sides;
        const px = Math.cos(a) * radius;
        const py = Math.sin(a) * radius;
        if (i === 0) this.ctx.moveTo(px, py);
        else this.ctx.lineTo(px, py);
      }
      this.ctx.closePath();
      this.ctx.strokeStyle = track.primaryColor;
      this.ctx.lineWidth = 2 * glowIntensity;
      this.ctx.shadowColor = track.secondaryColor;
      this.ctx.shadowBlur = 16 * glowIntensity;
      this.ctx.stroke();

      // Inverted inner triangle
      this.ctx.rotate(-this.time * 0.9);
      this.ctx.beginPath();
      for (let j = 0; j < 3; j++) {
        const a = (j * 2 * Math.PI) / 3;
        const px = Math.cos(a) * (radius * 0.58);
        const py = Math.sin(a) * (radius * 0.58);
        if (j === 0) this.ctx.moveTo(px, py);
        else this.ctx.lineTo(px, py);
      }
      this.ctx.closePath();
      this.ctx.strokeStyle = track.secondaryColor;
      this.ctx.stroke();
      this.ctx.restore();
    }

    // 6. Supernova (stellar core and radial flares shooting symmetrically from behind album cover)
    renderSupernova(track) {
      const { cx, cy } = this.getCenter();
      const pulse = isPlaying ? Math.sin(this.time * 3.5) * 8 + 36 : 28;

      this.ctx.save();
      const grad = this.ctx.createRadialGradient(cx, cy, 0, cx, cy, pulse * 2.8);
      grad.addColorStop(0, '#ffffff');
      grad.addColorStop(0.3, track.primaryColor);
      grad.addColorStop(0.8, track.secondaryColor);
      grad.addColorStop(1, 'transparent');

      this.ctx.fillStyle = grad;
      this.ctx.beginPath();
      this.ctx.arc(cx, cy, pulse * 2.8, 0, Math.PI * 2);
      this.ctx.fill();

      // Flare rays
      const rays = 10;
      this.ctx.strokeStyle = track.primaryColor;
      this.ctx.lineWidth = 1.6;
      for (let k = 0; k < rays; k++) {
        const a = (k * Math.PI) / rays + this.time * 0.3;
        this.ctx.beginPath();
        this.ctx.moveTo(cx - Math.cos(a) * 110, cy - Math.sin(a) * 110);
        this.ctx.lineTo(cx + Math.cos(a) * 110, cy + Math.sin(a) * 110);
        this.ctx.stroke();
      }
      this.ctx.restore();
    }
  }

  // ==========================================================================
  // Event Listeners & UI Binding
  // ==========================================================================
  document.addEventListener('DOMContentLoaded', () => {
    initLanguage();
    const visualizer = new VisualizerEngine('visualizerCanvas');

    // Play/Pause button
    const playBtn = document.getElementById('playPauseBtn');
    if (playBtn) {
      playBtn.addEventListener('click', () => {
        isPlaying = !isPlaying;
        initWebAudio();
        if (audioContext && audioContext.state === 'suspended') {
          audioContext.resume();
        }
        updatePlayerHUD();
      });
    }

    // Track Navigation
    const nextBtn = document.getElementById('nextTrackBtn');
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        currentTrackIndex = (currentTrackIndex + 1) % demoTracks.length;
        currentTimeSec = 0;
        updatePlayerHUD();
      });
    }

    const prevBtn = document.getElementById('prevTrackBtn');
    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        currentTrackIndex = (currentTrackIndex - 1 + demoTracks.length) % demoTracks.length;
        currentTimeSec = 0;
        updatePlayerHUD();
      });
    }

    // Audio Sound Mute Toggle
    const soundBtn = document.getElementById('soundToggleBtn');
    if (soundBtn) {
      soundBtn.addEventListener('click', () => {
        initWebAudio();
        isAudioMuted = !isAudioMuted;
        if (synthGain && audioContext) {
          synthGain.gain.setValueAtTime(isAudioMuted ? 0 : 0.08, audioContext.currentTime);
        }
        soundBtn.innerHTML = isAudioMuted ? '🔇' : '🔊';
        soundBtn.title = isAudioMuted ? 'Unmute Ambient Sound' : 'Mute Ambient Sound';
      });
    }

    // Mode Buttons
    const modePills = document.querySelectorAll('.mode-pill');
    modePills.forEach(pill => {
      pill.addEventListener('click', () => {
        modePills.forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        visualizerMode = pill.getAttribute('data-mode') || 'neonPulse';
      });
    });

    // Sliders
    const glowSlider = document.getElementById('glowSlider');
    if (glowSlider) {
      glowSlider.addEventListener('input', (e) => {
        glowIntensity = parseFloat(e.target.value);
        updatePlayerHUD();
      });
    }

    const edgeWidthSlider = document.getElementById('edgeWidthSlider');
    if (edgeWidthSlider) {
      edgeWidthSlider.addEventListener('input', (e) => {
        edgeThickness = parseInt(e.target.value, 10);
        updatePlayerHUD();
      });
    }

    const speedSlider = document.getElementById('speedSlider');
    if (speedSlider) {
      speedSlider.addEventListener('input', (e) => {
        speedMultiplier = parseFloat(e.target.value);
      });
    }

    // Viewport Fullscreen Ambilight Toggle
    const vpBtn = document.getElementById('viewportAmbilightBtn');
    const vpAmbilight = document.getElementById('viewportAmbilight');
    if (vpBtn && vpAmbilight) {
      vpBtn.addEventListener('click', () => {
        isViewportAmbilightActive = !isViewportAmbilightActive;
        vpAmbilight.classList.toggle('active', isViewportAmbilightActive);
        vpBtn.style.background = isViewportAmbilightActive ? 'var(--cyan-primary)' : 'rgba(0, 242, 254, 0.15)';
        vpBtn.style.color = isViewportAmbilightActive ? '#000' : '#fff';
        const labelSpan = vpBtn.querySelector('span:last-child');
        if (labelSpan) {
          const dict = translations[currentLang] || translations.en;
          labelSpan.textContent = isViewportAmbilightActive ? dict.btnViewportAmbilightActive : dict.btnViewportAmbilight;
        }
      });
    }

    // Ambilight Palette Buttons
    const paletteBtns = document.querySelectorAll('.ambilight-palette-btn');
    paletteBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        paletteBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentPaletteMode = btn.getAttribute('data-palette') || 'album';
        updatePlayerHUD();
      });
    });

    // Installation Tabs
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    tabBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        tabBtns.forEach(b => b.classList.remove('active'));
        tabContents.forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        const targetId = btn.getAttribute('data-tab');
        const targetEl = document.getElementById(targetId);
        if (targetEl) targetEl.classList.add('active');
      });
    });

    // Code Copy Buttons
    document.querySelectorAll('button.btn-copy').forEach(btn => {
      btn.addEventListener('click', () => {
        const codeBlock = btn.closest('.code-block-card');
        const code = codeBlock ? codeBlock.querySelector('.code-body').innerText : '';
        if (code) {
          navigator.clipboard.writeText(code).then(() => {
            const originalText = btn.textContent;
            btn.textContent = currentLang === 'ru' ? '✓ Скопировано' : '✓ Copied';
            btn.style.color = '#00f2fe';
            setTimeout(() => {
              btn.textContent = originalText;
              btn.style.color = '';
            }, 2000);
          });
        }
      });
    });

    // Initial HUD update
    updatePlayerHUD();
  });

})();
