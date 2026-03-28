# Ziba — Cross-Platform Art Wallpaper App

> Muzei-inspired. WikiArt-powered. Flutter everywhere.

## Overview

Ziba downloads art from WikiArt and sets it as your wallpaper daily. It works on macOS, Linux, Windows, Android, and iOS. Core features: daily rotation, favorites/history, manual refresh.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Flutter UI Layer                │
│   (Material 3, adaptive layouts, state mgmt)    │
├─────────────────────────────────────────────────┤
│              Core Business Logic                │
│  ┌───────────┐ ┌───────────┐ ┌───────────────┐ │
│  │ ArtService│ │ Scheduler │ │ FavoritesRepo │ │
│  │ (WikiArt) │ │ (Daily)   │ │ (SQLite/Hive) │ │
│  └───────────┘ └───────────┘ └───────────────┘ │
├─────────────────────────────────────────────────┤
│           Platform Wallpaper Adapter            │
│  ┌────────┐┌───────┐┌───────┐┌───────┐┌─────┐ │
│  │ macOS  ││ Linux ││Windows││Android││ iOS │ │
│  │osascript││feh/   ││ Power-││ Wall- ││Short│ │
│  │/NS API ││gsettng││ Shell ││ paper ││cuts │ │
│  └────────┘└───────┘└───────┘└───────┘└─────┘ │
└─────────────────────────────────────────────────┘
```

### Layer Breakdown

**1. Art Source Layer** (`lib/services/wikiart_service.dart`)
- WikiArt JSON API integration (free, read-only)
- Key endpoints:
  - `GET /en/App/Painting/MostViewedPaintings` — curated high-quality works
  - `GET /en/App/Painting/PaintingsByArtist?artistUrl={slug}&json=2`
  - `GET /en/App/Artist/AlphabetJson?v=new` — all artists index
  - Image URLs follow pattern: `https://uploads{N}.wikiart.org/images/{slug}/{filename}!Large.jpg`
- Caching: local JSON index + downloaded images in app support dir
- Fallback: Art Institute of Chicago API (no key, 100k+ open-access)

**2. Scheduler Layer** (`lib/services/scheduler_service.dart`)
- **Android**: `WorkManager` via `workmanager` Flutter plugin (periodic 24h task)
- **iOS**: `BGTaskScheduler` via platform channel (best-effort, iOS is restrictive)
- **macOS**: `launchd` plist installed to `~/Library/LaunchAgents/`
- **Linux**: `systemd` user timer or cron
- **Windows**: Task Scheduler via PowerShell

**3. Wallpaper Adapter** (`lib/platform/wallpaper_adapter.dart`)

| Platform | Method | Notes |
|----------|--------|-------|
| **macOS** | `osascript` → AppleScript `tell application "System Events"` or `NSWorkspace.shared.setDesktopImageURL` via FFI | Both monitors supported |
| **Linux** | `gsettings set org.gnome.desktop.background picture-uri` (GNOME), `feh --bg-fill` (i3/other), `plasma-apply-wallpaperimage` (KDE) | Detect DE at runtime |
| **Windows** | `SystemParametersInfoW` via FFI or PowerShell | Registry for slideshow |
| **Android** | `WallpaperManager` via platform channel | Home + Lock screen |
| **iOS** | Shortcut/widget workaround (iOS doesn't allow programmatic wallpaper) | Show in widget + notification with "Set as Wallpaper" prompt |

**4. Storage Layer**
- **Local DB**: `drift` (SQLite) for history, favorites, metadata
- **Image cache**: `path_provider` app support dir, LRU eviction (keep last 30)
- **Settings**: `shared_preferences` for interval, art movement filters, etc.

---

## WikiArt API Reference (Key Endpoints)

```
Base: https://www.wikiart.org/en/App

# List all artists (paginated)
GET /Artist/AlphabetJson?v=new&paginationToken={token}

# Paintings by artist
GET /Painting/PaintingsByArtist?artistUrl={slug}&json=2

# Most viewed (good for "daily pick" rotation)
GET /Painting/MostViewedPaintings

# Painting detail
GET /Painting/ImageJson/{contentId}

# Artists by art movement
GET /Artist/AlphabetJson?v=new&artistsByDictionaryFilter={movementId}

# Auth (if needed): append &authSessionKey={key} from login
POST /User/Login?accessCode={access}&secretCode={secret}
```

Response shape for paintings:
```json
{
  "title": "The Birth of Venus",
  "contentId": 189114,
  "artistName": "Sandro Botticelli",
  "completitionYear": 1485,
  "width": 1600,
  "height": 1067,
  "image": "https://uploads6.wikiart.org/images/sandro-botticelli/the-birth-of-venus-1485(1).jpg!Large.jpg"
}
```

---

## Project Structure

```
ziba/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/
│   │   ├── artwork.dart            # Artwork data model
│   │   └── artwork.g.dart          # Generated JSON serialization
│   ├── services/
│   │   ├── wikiart_service.dart    # WikiArt API client
│   │   ├── art_source.dart         # Abstract art source interface
│   │   ├── image_cache_service.dart # Download + LRU cache
│   │   └── scheduler_service.dart  # Background task scheduling
│   ├── platform/
│   │   ├── wallpaper_adapter.dart  # Abstract + factory
│   │   ├── wallpaper_macos.dart    # macOS implementation
│   │   ├── wallpaper_linux.dart    # Linux implementation
│   │   ├── wallpaper_windows.dart  # Windows implementation
│   │   ├── wallpaper_android.dart  # Android implementation
│   │   └── wallpaper_ios.dart      # iOS (limited) implementation
│   ├── data/
│   │   ├── database.dart           # Drift DB definition
│   │   ├── favorites_repo.dart     # Favorites CRUD
│   │   └── history_repo.dart       # Wallpaper history
│   ├── state/
│   │   ├── app_state.dart          # Riverpod providers
│   │   └── settings_state.dart     # User preferences
│   └── ui/
│       ├── screens/
│       │   ├── home_screen.dart    # Current wallpaper + controls
│       │   ├── history_screen.dart # Past wallpapers grid
│       │   ├── favorites_screen.dart
│       │   └── settings_screen.dart
│       ├── widgets/
│       │   ├── artwork_card.dart
│       │   ├── artwork_detail.dart
│       │   └── refresh_button.dart
│       └── theme.dart
├── android/
│   └── app/src/main/kotlin/.../WallpaperPlugin.kt
├── ios/
│   └── Runner/WallpaperPlugin.swift
├── macos/
│   └── Runner/WallpaperPlugin.swift
├── linux/
│   └── wallpaper_plugin.cc
├── windows/
│   └── wallpaper_plugin.cpp
├── pubspec.yaml
└── test/
```

---

## State Management: Riverpod

```
artworkProvider       → AsyncNotifier<Artwork>  (current artwork)
historyProvider       → StreamNotifier<List<Artwork>>
favoritesProvider     → StreamNotifier<List<Artwork>>
settingsProvider      → Notifier<AppSettings>
wallpaperProvider     → FutureProvider (set wallpaper action)
```

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  # Network
  dio: ^5.4.0
  # Storage
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  # Image
  cached_network_image: ^3.3.0
  # Background tasks (Android)
  workmanager: ^0.5.2
  # UI
  google_fonts: ^6.1.0
  shimmer: ^3.0.0
  # Utilities
  json_annotation: ^4.8.0
  freezed_annotation: ^2.4.0
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  freezed: ^2.4.0
  drift_dev: ^2.16.0
  riverpod_generator: ^2.3.0
  flutter_lints: ^3.0.0
```

---

## Platform Wallpaper Commands

### macOS
```bash
osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/path/to/image.jpg"'
```
Or via Swift MethodChannel:
```swift
let workspace = NSWorkspace.shared
let screen = NSScreen.main!
try workspace.setDesktopImageURL(URL(fileURLWithPath: path), for: screen, options: [:])
```

### Linux (auto-detect DE)
```bash
# GNOME
gsettings set org.gnome.desktop.background picture-uri "file:///path/to/image.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///path/to/image.jpg"

# KDE
plasma-apply-wallpaperimage /path/to/image.jpg

# Hyprland / sway
swaybg -i /path/to/image.jpg -m fill

# Fallback (X11)
feh --bg-fill /path/to/image.jpg
```

### Windows
```powershell
Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo(0x0014, 0, "C:\path\to\image.jpg", 0x01 -bor 0x02)
```

### Android
```kotlin
val manager = WallpaperManager.getInstance(context)
val bitmap = BitmapFactory.decodeFile(path)
manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
```

### iOS (Limited)
iOS does not allow programmatic wallpaper setting. Alternatives:
1. **Widget**: Show current artwork in a home screen widget
2. **Share sheet**: "Set as Wallpaper" button opens iOS share → Save Image
3. **Shortcut**: Create an iOS Shortcut that sets wallpaper from Photos (iOS 16+)

---

## MVP Roadmap

### Phase 1: Core (Week 1-2)
- [ ] WikiArt service with caching
- [ ] Artwork model + drift database
- [ ] History + favorites repository
- [ ] Manual refresh (fetch random artwork, display in app)
- [ ] macOS wallpaper adapter (osascript)

### Phase 2: Daily Rotation (Week 3)
- [ ] Background scheduler per platform
- [ ] Android WorkManager integration
- [ ] macOS launchd plist
- [ ] Linux systemd timer
- [ ] Settings screen (interval, art movement filter)

### Phase 3: All Platforms (Week 4)
- [ ] Windows wallpaper adapter
- [ ] Linux DE detection + adapter
- [ ] Android platform channel
- [ ] iOS widget + share sheet fallback
- [ ] Polish UI, adaptive layouts

### Phase 4: Delight (Week 5+)
- [ ] Art movement / style filters
- [ ] Artist deep-dive screens
- [ ] Notification with artwork info
- [ ] System tray / menu bar app (desktop)
- [ ] Art Institute of Chicago as second source
- [ ] Landscape-only filter for desktop wallpapers

---

## Naming Candidates

| Name | Available? | Vibe |
|------|-----------|------|
| **Ziba** | Clean, obvious | Gallery meets wallpaper |
| **Galerie** | French sophistication | Museum-grade taste |
| **DailyCanvas** | Descriptive | Canvas = screen + painting |
| **Mural** | One word, strong | Wall art, public art |
| **Easel** | Art tool metaphor | Your screen is the canvas |

---

## Design Direction

Swiss-minimal. JetBrains Mono for metadata. System serif for artwork titles. 
Let the art breathe — max whitespace, no chrome. Dark mode default.
Inspiration: Muzei's blur effect, but cleaner. Gallery-like presentation.
