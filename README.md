# 🎵 Vibe Music

A **premium iOS music app** with Liquid Glass design, YouTube/Spotify search, offline downloads, and Google account sync.

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🎨 Liquid Glass UI | Electric green theme, blur effects, glow animations |
| 🔍 Multi-source Search | YouTube Music + YouTube + Spotify via API |
| 📖 Lyrics | Auto-fetched from Lyrics.ovh + Genius fallback |
| ⬇️ Offline Downloads | Background download, plays without internet |
| 🔊 High Quality Audio | Up to 320kbps / Lossless via Invidious |
| 🔐 Google Sign In | Library synced to your Google account |
| 📚 Libraries | Create playlists, like songs, manage queue |
| 🎛️ Now Playing | Lock screen controls, AirPlay, CarPlay-ready |
| 📱 Mini Player | Drag-up gesture to open full player |

---

## 🚀 Build via GitHub Actions

### 1. Fork / push to GitHub

```bash
git init
git add .
git commit -m "feat: initial Vibe Music"
git remote add origin https://github.com/YOUR_USERNAME/VibeMusic
git push -u origin main
```

### 2. Add Repository Secrets

Go to **Settings → Secrets → Actions** and add:

| Secret | Where to get it |
|--------|----------------|
| `GOOGLE_CLIENT_ID` | [Google Cloud Console](https://console.cloud.google.com) → Credentials → iOS OAuth ID |
| `GOOGLE_URL_SCHEME` | Same place (reversed client ID, e.g. `com.googleusercontent.apps.XXXXX`) |
| `YOUTUBE_API_KEY` | Google Cloud → APIs → YouTube Data API v3 |
| `RAPID_API_KEY` | [rapidapi.com](https://rapidapi.com) (for Spotify search & Genius lyrics) |

> **Don't have API keys yet?** The app runs in demo mode with mock data — you can still build and test.

### 3. Trigger Build

- Push to `main` → auto-build
- Or go to **Actions → Build Vibe Music IPA → Run workflow**

### 4. Install IPA

Download the artifact from Actions → install via:
- **TrollStore** (recommended, no PC needed)
- **Sideloadly** / **AltStore**
- **Scarlet / Feather**

---

## 🔧 Local Development (requires Mac)

```bash
brew install xcodegen
xcodegen generate
open VibeMusic.xcodeproj
```

---

## 📁 Project Structure

```
VibeMusic/
├── Sources/VibeMusic/
│   ├── VibeApp.swift              # App entry
│   ├── Views/
│   │   ├── ContentView.swift      # Tab navigation
│   │   ├── HomeView.swift         # Home feed
│   │   ├── SearchView.swift       # Multi-source search
│   │   ├── LibraryView.swift      # Playlists & liked songs
│   │   ├── ProfileView.swift      # Google auth & settings
│   │   ├── FullPlayerView.swift   # Full-screen player + lyrics
│   │   └── MiniPlayerView.swift   # Persistent mini player
│   ├── Services/
│   │   ├── GoogleAuthService.swift
│   │   ├── MusicSearchService.swift
│   │   ├── AudioPlayerService.swift
│   │   ├── YouTubeAudioExtractor.swift
│   │   ├── DownloadService.swift
│   │   ├── LibraryService.swift
│   │   └── LyricsService.swift
│   ├── Models/Track.swift
│   ├── Components/
│   │   ├── TrackRow.swift
│   │   └── LiquidGlassTabBar.swift
│   └── Extensions/VibeColors.swift
├── project.yml                    # XcodeGen config
├── .github/workflows/build.yml   # CI/CD
└── generate_icon.py              # Icon generator
```

---

## 🎨 Design System

- **Primary color**: `#2EEB70` (Electric Green)
- **Background**: `#0A0F0A` (Near Black)
- **Glass effect**: `.ultraThinMaterial` + custom stroke
- **Glow layers**: Triple shadow with opacity falloff
- **Typography**: SF Pro (system font, optimized for music UIs)

---

## ⚙️ Audio Quality Options

| Quality | Bitrate | Notes |
|---------|---------|-------|
| Standard | 128 kbps | Saves data |
| High | 256 kbps | **Default** |
| Ultra | 320 kbps | Best MP3 quality |
| Lossless | FLAC | Where available |

Audio is streamed via [Invidious](https://invidious.io) open-source YouTube front-ends — no yt-dlp binary required on device.

---

## 📝 Notes

- The app is **unsigned** — use TrollStore or a signing service to install
- Google Sign In requires a real OAuth 2.0 client ID (iOS type)
- YouTube audio extraction uses public Invidious API instances
- For production: host your own Invidious instance for reliability
