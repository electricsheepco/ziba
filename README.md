# Ziba

> Your screen. Their masterpiece.

Cross-platform art wallpaper app powered by WikiArt. Muzei-inspired, Flutter-built.

## Install (macOS)

**Homebrew (recommended)**

```bash
brew install --cask electricsheepco/tap/ziba
```

**Direct download**

Download `ziba.dmg` from the [latest release](https://github.com/electricsheepco/ziba/releases/latest), open it, and drag ziba to your Applications folder.

Signed and notarised — no Gatekeeper warnings.

## What it does

- Downloads fine art from WikiArt's 250k+ collection
- Sets it as your wallpaper daily (or on your schedule)
- Works on macOS, Linux, Windows, Android (iOS: view + save)
- Keeps a history of past wallpapers
- Save favorites for later

## Quick Start

```bash
# Clone and setup
git clone <repo>
cd ziba

# Install dependencies
flutter pub get

# Generate code (freezed, drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run on your platform
flutter run -d macos    # or linux, windows, android, ios
```

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for full details.

```
Flutter UI → Riverpod State → WikiArt Service → Platform Wallpaper Adapter
                                    ↓
                              Drift SQLite DB
                          (history + favorites)
```

## WikiArt API

The app uses WikiArt's free read-only JSON API. For higher rate limits,
register at [wikiart.org/en/App/GetApi](https://www.wikiart.org/en/App/GetApi)
and add your keys in Settings.

## Platform Support

| Platform | Wallpaper | Background Refresh | Status |
|----------|-----------|-------------------|--------|
| macOS    | osascript | launchd           | ✅ Ready |
| Linux    | gsettings/feh/plasma | systemd/cron | ✅ Ready |
| Windows  | SystemParametersInfo | Task Scheduler | ✅ Ready |
| Android  | WallpaperManager | WorkManager    | ✅ Ready |
| iOS      | Save to Photos | Limited (iOS restriction) | ⚠️ Partial |

## Stack

- Flutter 3.x + Dart 3.x
- Riverpod (state)
- Drift (SQLite)
- Dio (HTTP)
- Freezed (data classes)
- Google Fonts (Playfair Display + JetBrains Mono)

## License

MIT
