# 2026-03-29 — Signing, polish, bug fixes

## Session Summary
Signed, notarised, and shipped ziba v1.0.0 and v1.1.0 via Homebrew tap. Added DIM/TONE/SET to History/Saved detail screen. Fixed crop slider visual feedback and DIM/TONE reapply bug.

## What Got Done
- [x] macOS code signing with Developer ID Application: Rajhesh Panchanadhan (WP225PXMBH)
- [x] Notarised + stapled (xcrun notarytool + xcrun stapler)
- [x] Gatekeeper verdict: accepted, source=Notarized Developer ID
- [x] Homebrew tap created: electricsheepco/homebrew-tap
- [x] GitHub releases: v1.0.0 and v1.1.0 at electricsheepco/ziba
- [x] Custom ز icon (SFArabic font, lapis #6B8EC4, Girih background, dark #0A0A0F)
- [x] All 7 icon sizes generated and replaced (16–1024px)
- [x] DIM/TONE/SET panel in ArtworkDetailScreen (History + Saved)
- [x] SET panel animates in with slide-up (220ms easeOutCubic)
- [x] ESC dismisses SET panel
- [x] Polish: hover states on PanelButton, tooltips on overlay buttons, friendly error messages
- [x] History style tag 7px → 9px
- [x] Gradient overlay standardised (0xCC000000 everywhere)
- [x] Crop slider fix: image now pans live using alignment property
- [x] DIM/TONE reapply fix: timestamp in temp filename forces macOS to reload

## Key Volume Quirk
/Volumes/zodlightning is mounted with `noowners` flag — always run codesign from Terminal.app (not Warp) to avoid permission denied errors.

## TODO (Next Session)
- [ ] Art movement filter in Settings not working — debug
- [ ] Fallback logic when WikiArt doesn't return art movement metadata
- [ ] Crop slider: add trackpad gesture support (three-finger scroll, pinch zoom)
- [ ] Arabic ز mismatch: icon uses SFArabic, ZibaLogo widget uses Georgia (Flutter fallback) — need to align
- [ ] Dark/Light/System theme toggle in Settings
- [ ] Menubar app + launch at login (next iteration)
- [ ] Android build planning (Google Play)

## Key Files
- `lib/ui/screens/artwork_detail_screen.dart` — DIM/TONE/SET panel
- `lib/ui/screens/home_screen.dart` — crop slider image panning
- `lib/platform/wallpaper_adapter.dart` — macOS setWallpaper via osascript
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/` — new ز icons
- `/tmp/homebrew-tap/Casks/ziba.rb` — Homebrew formula (v1.1.0)
