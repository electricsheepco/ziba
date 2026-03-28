# 2026-03-27 — Build fixes + home redesign spec

## Session Summary
Got the app building and running on macOS (Flutter + Riverpod + Drift + Freezed). Fixed a cascade of build/runtime issues. Designed the next UI iteration — full spec written, ready to implement tomorrow.

## What Got Done
- [x] Fixed missing `import 'package:drift/drift.dart' show Value'` in `app_state.dart`
- [x] Ran `build_runner` — codegen confirmed clean
- [x] Added `com.apple.security.network.client` to both entitlement files
- [x] Diagnosed stale sandbox container (Darwin 25 / macOS 16 beta doesn't honour `network.client` in sandbox) — disabled `app-sandbox` in both `DebugProfile.entitlements` and `Release.entitlements`
- [x] Fixed `addToHistory` overwriting artwork data with empty strings (was corrupting SAVE)
- [x] Locked window to 540×680, centered, non-resizable (`MainFlutterWindow.swift`)
- [x] App fetching WikiArt paintings (Basquiat confirmed working)
- [x] Full redesign spec written: `docs/superpowers/specs/2026-03-27-home-redesign-design.md`

## Spec Summary (to implement tomorrow)
1. **Layout** — no-scroll, full-bleed image + 64pt right action column (NEW / SAVE / SET icons)
2. **Metadata overlay** — fades in on load, auto-fades after 5s, tap to toggle; title + artist + year only
3. **NEW fix** — `refresh(setWallpaper: false)` — never auto-sets wallpaper
4. **SAVE fix** — heart icon toggles filled/outline via `isFavoriteProvider`
5. **SET crop picker** — screen-ratio selection box + horizontal slider to pan; crops image with `dart:ui` before setting; always shown before setting
6. **Small caps** — `FontFeature.smallCaps()` throughout; "ziba" wordmark `letterSpacing: 6, w300`
7. **SAVED detail** — tap card → full-image detail screen; two overlay icons bottom-right (SET + REMOVE); REMOVE deletes from DB + deletes local file from disk

## Files Already Changed
- `lib/state/app_state.dart` — drift Value import
- `lib/data/database.dart` — addToHistory fix
- `macos/Runner/MainFlutterWindow.swift` — window size
- `macos/Runner/DebugProfile.entitlements` — sandbox disabled
- `macos/Runner/Release.entitlements` — sandbox disabled + network.client

## TODO (Next Session)
- [ ] Write implementation plan from the spec (`superpowers:writing-plans`)
- [ ] Implement: home_screen.dart full rewrite
- [ ] Implement: artwork_detail_screen.dart (new file)
- [ ] Implement: favorites_screen.dart tap navigation
- [ ] Implement: small caps in main.dart theme
- [ ] Implement: `refresh(setWallpaper: false)` in app_state.dart call sites

## Key Files
- Spec: `docs/superpowers/specs/2026-03-27-home-redesign-design.md`
- App state: `lib/state/app_state.dart`
- DB: `lib/data/database.dart`
- Home: `lib/ui/screens/home_screen.dart`
- Favorites: `lib/ui/screens/favorites_screen.dart`

## Tags
ziba flutter wikiart wallpaper macos
