# Ziba — Home Screen Redesign
**Date:** 2026-03-27

---

## Scope

Six changes in one pass:

1. Home screen layout — no-scroll, full-bleed image with right-side action column
2. Metadata overlay — fades in on load, auto-fades out, tap to toggle
3. NEW fix — fetch artwork without auto-setting wallpaper
4. SAVE fix — data bug patched; UI gets toggle state (heart fills/empties)
5. SET — crop/region picker for wide images before setting wallpaper
6. Small caps typography — consistent across all text in the app

---

## 1. Home Screen Layout

### Structure

Replace the current `CustomScrollView` / `SliverToBoxAdapter` layout with a flat, non-scrollable structure:

```
Scaffold
└── Column
    ├── Expanded
    │   └── Row
    │       ├── Expanded          ← image + overlay (Stack)
    │       └── SizedBox(w:64)    ← action button column
    └── NavigationBar
```

The `Expanded` row fills all available space between the top of the scaffold and the navigation bar. No scrolling anywhere in the home tab.

### Image

- `ClipRRect(borderRadius: 4)` wrapping a `CachedNetworkImage`
- `fit: BoxFit.cover` — fills the available space completely
- The image fills the full height of the `Expanded` area

### Action Button Column (right, 64pt wide)

Three icon buttons stacked vertically, `MainAxisAlignment.spaceEvenly`:

| Button | Icon | Action |
|--------|------|--------|
| NEW | `Icons.refresh` | fetch new artwork, do NOT set wallpaper |
| SAVE | `Icons.favorite` / `Icons.favorite_border` | toggle favorite |
| SET | `Icons.wallpaper` | open crop picker → set wallpaper |

- Each button: 44×44 touch target
- SAVE icon: filled when already in favorites, outline when not — reads `isFavoriteProvider(contentId)`
- Muted color at rest, white on active/press
- No labels — icons only

---

## 2. Metadata Overlay

### Trigger & Timing

- **On artwork load:** overlay fades IN automatically (300ms)
- **Auto-dismiss:** fades OUT after 5 seconds (500ms)
- **Tap image:** toggles visibility; re-starts 5s timer when toggling on
- **Crop mode active:** overlay is hidden and non-interactive

### Visual Structure

Pinned to the bottom of the image via `Stack` + `Positioned`:

```
Stack
├── image (Positioned.fill)
├── GestureDetector (Positioned.fill, transparent)
└── AnimatedOpacity (Positioned bottom:0, left:0, right:0)
    └── Container (gradient decoration, padding: 16)
        └── Column
            ├── Text — title (Playfair Display, 22sp, white)
            ├── Text — artistName (JetBrains Mono, 13sp, white 80%)
            └── Text — year (JetBrains Mono, 11sp, white 50%)
```

### Gradient

```dart
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
)
```

Applied over the bottom 40% of the image area.

### State (in `_ArtworkDisplayState`)

```dart
bool _overlayVisible = true;
Timer? _dismissTimer;

void _showOverlay() {
  setState(() => _overlayVisible = true);
  _dismissTimer?.cancel();
  _dismissTimer = Timer(const Duration(seconds: 5), _hideOverlay);
}

void _hideOverlay() => setState(() => _overlayVisible = false);
```

Called via `initState` and `didUpdateWidget` when the artwork changes.

---

## 3. NEW — No Auto-Wallpaper

`CurrentArtworkNotifier.refresh()` already accepts `setWallpaper` flag (defaults `true`).

Change every call-site in the UI to `refresh(setWallpaper: false)`.

The SET button is the sole trigger for wallpaper setting.

---

## 4. SAVE — Toggle State

Data bug is fixed (`addToHistory` no longer overwrites artwork). UI change:

- Read `isFavoriteProvider(artwork.contentId)` to determine icon fill state
- Tap: if not saved → `db.addFavorite(contentId)`; if saved → `db.removeFavorite(contentId)`
- No snackbar — icon state change is sufficient feedback

---

## 5. SET — Crop / Region Picker

### Problem

Wide murals and panoramic paintings (e.g. Rivera's *Pan American Unity*, aspect ratio ~3:1) look terrible when the OS stretches or letterboxes them. The user needs to choose which region to use.

### When it activates

SET is tapped → **always** shows the crop picker before setting. For artwork that already fits the screen ratio, the crop box covers nearly the full image and the slider has minimal travel — no friction for normal cases.

### Crop picker UI

The crop picker replaces the metadata overlay within the same image `Stack`. State flag `_cropMode: bool` controls which overlay is active.

```
Stack
├── image (Positioned.fill, dimmed to 50% opacity)
├── _CropOverlay (Positioned.fill)
│   ├── dark mask left of selection box
│   ├── bright border rect (selection box, screen aspect ratio)
│   └── dark mask right of selection box
├── Positioned(bottom: 16) — Slider (pan position 0.0–1.0)
└── Positioned(bottom: 64) — Row [ ✕ Cancel ]  [ ✓ Apply ]
```

### Selection box

- Fixed aspect ratio = current screen width : screen height (from `MediaQuery`)
- Width of box = `min(imageRenderWidth, imageRenderHeight * screenAspectRatio)`
- Horizontal position controlled by slider
- Box is drawn via `CustomPainter` — dark semi-transparent rectangles on either side, bright `1.5pt` white border around the selected region

### Slider

- `Slider(value: _panOffset, min: 0, max: 1)`
- Only rendered if `imageAspectRatio > screenAspectRatio` (image is wider than screen)
- For portrait or square images: slider hidden, box is centred and covers full width

### On Apply

1. Load the local image file: `File(artwork.localPath!)`
2. Decode with `dart:ui` → `ui.Codec` → `ui.FrameInfo` → `ui.Image`
3. Calculate source rect from `_panOffset`, image native dimensions, and screen aspect ratio
4. Draw cropped region to `ui.PictureRecorder` canvas at native resolution
5. Export to PNG in temp directory
6. Call `adapter.setWallpaper(croppedPath)`
7. Exit crop mode

### On Cancel

Exit crop mode, restore metadata overlay visibility.

### Dependencies

No new packages — uses `dart:ui` (already available in Flutter) for image crop.

---

## 6. Small Caps Typography

Apply `fontFeatures: [FontFeature.smallCaps()]` to body and label styles in `main.dart`'s `_buildTheme`.

Affected styles: `bodyLarge`, `bodyMedium`, `labelSmall`, `AppBarTheme.titleTextStyle`.

The "ZIBA" wordmark in the empty state: `letterSpacing: 6, fontWeight: FontWeight.w300`.

---

## 7. Window Size (already implemented)

Fixed at 540×680, centered on launch, non-resizable. Done in `MainFlutterWindow.swift`.

---

## 8. Set from SAVED Tab

Tapping a saved artwork card opens a full-screen detail view — full-bleed image filling the window (no right-side action column). Two icon buttons float over the **bottom-right corner** of the image.

### Navigation

`FavoritesScreen` → `Navigator.push` → `ArtworkDetailScreen(artwork: ArtworkData)`

No shared layout widget needed — the detail screen is simpler than the home screen (no action column, no NEW button).

### ArtworkData value object

Both screens share a lightweight data object to avoid coupling to either the drift row type or the Freezed model:

```dart
class ArtworkData {
  final int contentId;
  final String title;
  final String artistName;
  final int? completitionYear;
  final String imageUrl;
  final String? localPath;
  final int? width;
  final int? height;
}
```

### Detail screen layout

```
Stack (fills window between top and nav bar)
├── image (Positioned.fill, BoxFit.cover)
├── metadata overlay (Positioned bottom:0, same fade behaviour as home)
└── Positioned(bottom: 16, right: 16)
    └── Row
        ├── _OverlayIconButton(Icons.wallpaper)   ← SET
        └── _OverlayIconButton(Icons.delete)       ← REMOVE
```

`_OverlayIconButton` — small circular button, dark semi-transparent background, white icon.

### SET action

Same crop picker flow as the home screen. Downloads image first if `localPath` is null or file doesn't exist.

### REMOVE action

1. `db.removeFavorite(contentId)` — deletes the row from `favorites` table
2. If `localPath != null` and `File(localPath).existsSync()` → `File(localPath).deleteSync()` — removes the cached image from disk
3. `Navigator.pop()` — returns to the SAVED grid

The database method `removeFavorite` stays as-is (only touches the favorites table). The file deletion is handled at the call site in the UI, keeping the DB layer clean.

### Image loading

If `localPath` is set and the file exists → `FileImage(File(localPath))`.
Otherwise → `CachedNetworkImage(imageUrl)`.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/ui/screens/home_screen.dart` | Full layout rewrite — new layout, overlay, crop picker |
| `lib/ui/screens/favorites_screen.dart` | Tap card → navigate to `ArtworkDetailScreen` |
| `lib/ui/screens/artwork_detail_screen.dart` | New screen — full image, two overlay icons (SET + REMOVE) |
| `lib/state/app_state.dart` | `refresh()` call sites → `setWallpaper: false` |
| `lib/main.dart` | Small caps font features in theme |
| `lib/data/database.dart` | `addToHistory` fix (already done) |
| `macos/Runner/MainFlutterWindow.swift` | Window size (already done) |

No new packages.
