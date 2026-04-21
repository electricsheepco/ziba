# 2026-04-21 — Android + iOS Mobile Port

## What Got Done

- [x] Replaced broken `WallpaperPlugin.kt` (wrong package `com.ziba.app`, bad context via FlutterEngineCache) with correct `com.essco/ziba/WallpaperPlugin.kt` using direct context injection
- [x] Registered plugin in `MainActivity.configureFlutterEngine`; added `SET_WALLPAPER`, `INTERNET`, `RECEIVE_BOOT_COMPLETED` permissions to AndroidManifest
- [x] Implemented `AndroidWallpaperAdapter` — MethodChannel call to Kotlin `WallpaperManager` (home + lock screen)
- [x] Added `gal ^2.3.0` + `url_launcher ^6.3.1` to pubspec; added `NSPhotoLibraryAddUsageDescription` to iOS Info.plist
- [x] Implemented `IOSWallpaperAdapter` — saves artwork to Photos Library via `gal.putImage()`
- [x] Created `IOSWallpaperSheet` — step-by-step instruction bottom sheet with Settings deep link
- [x] Home screen: platform-aware CTA ("SAVE" on iOS, "SET" on Android), shows iOS sheet on success, Android snackbar
- [x] WorkManager background auto-rotation: dispatcher isolate fetches artwork, downloads, sets wallpaper; 15-min minimum enforced; cancels when auto-rotate toggled off
- [x] Android release signing config in `build.gradle.kts`; `key.properties` + `*.jks` gitignored; `minSdk=24`
- [x] iOS `Podfile` minimum set to iOS 16.0
- [x] Upgraded `workmanager ^0.5.2` → `^0.9.0` (v1 embedding removed in current Flutter)
- [x] Pinned NDK to `27.1.12297006` (28.x install was malformed, missing `source.properties`)
- [x] Merged to main, pushed to origin, worktree cleaned up

## TODO (Next Session)

- [ ] **Generate Android signing keystore** (manual, interactive):
  ```bash
  keytool -genkey -v -keystore ~/ziba-release.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias ziba-key
  ```
- [ ] Create `android/key.properties` with keystore paths/passwords (see plan for format)
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Upload AAB to Google Play Console → Internal Testing track
- [ ] Open `ios/Runner.xcworkspace` in Xcode → set Team to WP225PXMBH → enable auto-signing
- [ ] Set iOS Deployment Target to 16.0 in Xcode Build Settings
- [ ] Build IPA: `flutter build ipa --release`
- [ ] Upload IPA to App Store Connect via Transporter
- [ ] Create Play Store and App Store listings (screenshots, descriptions, categories)
- [ ] Release v1.2.2 macOS (still unreleased — the original pending task)

## Key Files

- `android/app/src/main/kotlin/com/essco/ziba/WallpaperPlugin.kt` — new
- `android/app/src/main/kotlin/com/essco/ziba/MainActivity.kt` — updated
- `lib/platform/wallpaper_adapter.dart` — Android + iOS adapters implemented
- `lib/ui/widgets/ios_wallpaper_sheet.dart` — new
- `lib/ui/screens/home_screen.dart` — platform-aware CTA, iOS sheet trigger
- `lib/main.dart` — WorkManager init + dispatcher isolate
- `lib/state/app_state.dart` — WorkManager scheduling in autoRotateTimerProvider
- `android/app/build.gradle.kts` — release signing config

## Decisions

- iOS wallpaper: save to Photos + instruction sheet (no public API alternative)
- WorkManager minimum 15 min: Android OS enforces this; in-app timer still fires on shorter intervals when app is foregrounded
- NDK pinned to 27.1.12297006: the 28.x install is malformed on this machine
- workmanager upgraded to 0.9.0: 0.5.x uses v1 Flutter embedding APIs that are removed
