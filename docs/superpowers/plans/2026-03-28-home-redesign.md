# Home Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the home screen to full-bleed layout with right-side action column, metadata overlay, crop picker for SET, SAVE toggle, small caps typography, and a tap-through detail screen from Favorites.

**Architecture:** All new UI is concentrated in `home_screen.dart` (rewritten) and a new `artwork_detail_screen.dart`. A shared `ArtworkData` value object decouples both screens from the Freezed model and Drift row types. Crop rect logic is a pure function in its own file so it's unit-testable without Flutter.

**Tech Stack:** Flutter 3, Riverpod 2 (AsyncNotifier / FutureProvider.family), Drift, `dart:ui` for image crop, `cached_network_image`, `dart:async` (Timer).

---

### Task 1: Small Caps Typography

**Files:**
- Modify: `lib/main.dart`
- Test: `test/theme_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/main.dart';

void main() {
  test('bodyLarge has smallCaps font feature', () {
    final app = ZibaApp();
    final theme = app.buildTheme(Brightness.dark);
    final features = theme.textTheme.bodyLarge?.fontFeatures;
    expect(features, contains(const FontFeature.smallCaps()));
  });

  test('labelSmall has smallCaps font feature', () {
    final app = ZibaApp();
    final theme = app.buildTheme(Brightness.dark);
    final features = theme.textTheme.labelSmall?.fontFeatures;
    expect(features, contains(const FontFeature.smallCaps()));
  });
}
```

> Note: `_buildTheme` must be made accessible for testing. Change `_buildTheme` to `buildTheme` (remove leading underscore) in `ZibaApp`.

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Volumes/zodlightning/sites/ziba && flutter test test/theme_test.dart
```

Expected: FAIL — `buildTheme` method not found (it's currently `_buildTheme`).

- [ ] **Step 3: Implement — rename method and add smallCaps**

In `lib/main.dart`, change `_buildTheme` → `buildTheme` (two occurrences: definition and call site), then add `fontFeatures` to four styles:

```dart
// In ZibaApp:
theme: buildTheme(Brightness.light),    // was _buildTheme
darkTheme: buildTheme(Brightness.dark), // was _buildTheme

// In buildTheme():
bodyLarge: GoogleFonts.jetBrainsMono(
  fontSize: 14,
  fontFeatures: const [FontFeature.smallCaps()],
  color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF444444),
),
bodyMedium: GoogleFonts.jetBrainsMono(
  fontSize: 12,
  fontFeatures: const [FontFeature.smallCaps()],
  color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
),
labelSmall: GoogleFonts.jetBrainsMono(
  fontSize: 10,
  letterSpacing: 1.5,
  fontWeight: FontWeight.w500,
  fontFeatures: const [FontFeature.smallCaps()],
  color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
),
// AppBarTheme.titleTextStyle:
titleTextStyle: GoogleFonts.jetBrainsMono(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  letterSpacing: 2,
  fontFeatures: const [FontFeature.smallCaps()],
  color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
),
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/theme_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 5: Build check**

```bash
flutter build macos --debug 2>&1 | tail -5
```

Expected: `Build succeeded.`

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart test/theme_test.dart
git commit -m "feat: add smallCaps font feature to all body/label/appbar styles"
```

---

### Task 2: ArtworkData Value Object

**Files:**
- Create: `lib/models/artwork_data.dart`
- Test: `test/models/artwork_data_test.dart`

This shared lightweight object lets `HomeScreen` and `ArtworkDetailScreen` pass artwork without coupling to either the Freezed model or Drift row types.

- [ ] **Step 1: Write the failing test**

```dart
// test/models/artwork_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/models/artwork_data.dart';

void main() {
  test('ArtworkData holds all required fields', () {
    const data = ArtworkData(
      contentId: 42,
      title: 'The Starry Night',
      artistName: 'Vincent van Gogh',
      completitionYear: 1889,
      imageUrl: 'https://example.com/img.jpg',
      localPath: '/tmp/42.jpg',
      width: 921,
      height: 737,
    );

    expect(data.contentId, 42);
    expect(data.title, 'The Starry Night');
    expect(data.localPath, '/tmp/42.jpg');
    expect(data.width, 921);
  });

  test('localPath and dimensions are nullable', () {
    const data = ArtworkData(
      contentId: 1,
      title: 'Test',
      artistName: 'Artist',
      imageUrl: 'https://example.com/img.jpg',
    );

    expect(data.localPath, isNull);
    expect(data.width, isNull);
    expect(data.height, isNull);
    expect(data.completitionYear, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/models/artwork_data_test.dart
```

Expected: FAIL — `ArtworkData` not found.

- [ ] **Step 3: Create `lib/models/artwork_data.dart`**

```dart
import 'package:ziba/data/database.dart' as db_row;
import 'package:ziba/models/artwork.dart' as freezed_model;

/// Lightweight value object passed between screens.
///
/// Decouples UI from both the Freezed API model and the Drift DB row.
class ArtworkData {
  final int contentId;
  final String title;
  final String artistName;
  final int? completitionYear;
  final String imageUrl;
  final String? localPath;
  final int? width;
  final int? height;

  const ArtworkData({
    required this.contentId,
    required this.title,
    required this.artistName,
    this.completitionYear,
    required this.imageUrl,
    this.localPath,
    this.width,
    this.height,
  });

  /// From Freezed API model (used on HomeScreen after fetch).
  factory ArtworkData.fromModel(
    freezed_model.Artwork artwork, {
    String? localPath,
  }) =>
      ArtworkData(
        contentId: artwork.contentId,
        title: artwork.title,
        artistName: artwork.artistName,
        completitionYear: artwork.completitionYear,
        imageUrl: artwork.image,
        localPath: localPath,
        width: artwork.width,
        height: artwork.height,
      );

  /// From Drift DB row (used on FavoritesScreen).
  factory ArtworkData.fromRow(db_row.Artwork row) => ArtworkData(
        contentId: row.contentId,
        title: row.title,
        artistName: row.artistName,
        completitionYear: row.completitionYear,
        imageUrl: row.imageUrl,
        localPath: row.localPath,
        width: row.width,
        height: row.height,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/models/artwork_data_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/models/artwork_data.dart test/models/artwork_data_test.dart
git commit -m "feat: add ArtworkData value object shared between home and detail screens"
```

---

### Task 3: Fix refresh() Call Sites

**Files:**
- Modify: `lib/ui/screens/home_screen.dart` (3 call sites)

The SET button is the sole wallpaper trigger. NEW and auto-fetch must not set the wallpaper.

- [ ] **Step 1: Find all `refresh()` call sites in home_screen.dart**

```bash
grep -n "refresh()" /Volumes/zodlightning/sites/ziba/lib/ui/screens/home_screen.dart
```

Expected output — three lines:
- `_EmptyState`: `ref.read(currentArtworkProvider.notifier).refresh()`
- `_RefreshButton`: `ref.read(currentArtworkProvider.notifier).refresh()`
- `_ActionButton` NEW tap: `ref.read(currentArtworkProvider.notifier).refresh()`

- [ ] **Step 2: Change all three to `refresh(setWallpaper: false)`**

In `lib/ui/screens/home_screen.dart`, replace every:
```dart
ref.read(currentArtworkProvider.notifier).refresh()
```
with:
```dart
ref.read(currentArtworkProvider.notifier).refresh(setWallpaper: false)
```

There are 3 occurrences. Make all 3 changes.

- [ ] **Step 3: Build check**

```bash
flutter build macos --debug 2>&1 | tail -5
```

Expected: `Build succeeded.`

- [ ] **Step 4: Commit**

```bash
git add lib/ui/screens/home_screen.dart
git commit -m "fix: refresh() never auto-sets wallpaper — SET button is sole trigger"
```

---

### Task 4: Crop Rect Calculation (Pure Function)

**Files:**
- Create: `lib/ui/crop_math.dart`
- Test: `test/ui/crop_math_test.dart`

Extracting this as a pure function makes it unit-testable without Flutter or `dart:ui`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/ui/crop_math_test.dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/ui/crop_math.dart';

void main() {
  test('wide image: cropWidth = height * screenAspect', () {
    // Screen 540×680 → aspect = 0.7941...
    // Image 3000×1000 native
    // cropWidth = 1000 * (540/680) = 794.117...
    final rect = calculateCropRect(
      imageNativeSize: const Size(3000, 1000),
      screenSize: const Size(540, 680),
      panOffset: 0.0,
    );

    expect(rect.left, closeTo(0.0, 0.01));
    expect(rect.top, 0.0);
    expect(rect.width, closeTo(794.12, 0.5));
    expect(rect.height, 1000.0);
  });

  test('wide image: panOffset=1.0 moves box to right edge', () {
    final rect = calculateCropRect(
      imageNativeSize: const Size(3000, 1000),
      screenSize: const Size(540, 680),
      panOffset: 1.0,
    );

    // maxLeft = 3000 - 794.12 = 2205.88
    expect(rect.left, closeTo(2205.88, 1.0));
    expect(rect.right, closeTo(3000.0, 1.0));
  });

  test('portrait image: crop box covers full width', () {
    // Image taller than screen aspect → cropWidth = imageWidth
    final rect = calculateCropRect(
      imageNativeSize: const Size(800, 1200),
      screenSize: const Size(540, 680),
      panOffset: 0.0,
    );

    expect(rect.left, 0.0);
    expect(rect.width, 800.0); // clipped to imageWidth
  });

  test('square image with wide screen: cropWidth capped at imageWidth', () {
    final rect = calculateCropRect(
      imageNativeSize: const Size(1000, 1000),
      screenSize: const Size(1920, 1080),
      panOffset: 0.5,
    );

    expect(rect.width, 1000.0); // never exceeds image width
    expect(rect.left, 0.0);     // no pan room left
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/ui/crop_math_test.dart
```

Expected: FAIL — `calculateCropRect` not found.

- [ ] **Step 3: Create `lib/ui/crop_math.dart`**

```dart
import 'dart:ui';

/// Calculates the source crop rectangle for wallpaper cropping.
///
/// Returns a [Rect] in the image's native pixel coordinate space.
///
/// [imageNativeSize] — native pixel dimensions of the source image.
/// [screenSize] — current screen dimensions (from MediaQuery).
/// [panOffset] — 0.0 = leftmost position, 1.0 = rightmost position.
Rect calculateCropRect({
  required Size imageNativeSize,
  required Size screenSize,
  required double panOffset,
}) {
  final screenAspect = screenSize.width / screenSize.height;
  final cropWidth =
      (imageNativeSize.height * screenAspect).clamp(0.0, imageNativeSize.width);
  final maxLeft = imageNativeSize.width - cropWidth;
  final left = maxLeft * panOffset;

  return Rect.fromLTWH(left, 0, cropWidth, imageNativeSize.height);
}

/// Returns true if the slider should be shown.
///
/// Only shown when the image is wider than the screen aspect ratio.
bool needsPanSlider({
  required Size imageNativeSize,
  required Size screenSize,
}) {
  if (imageNativeSize.height == 0) return false;
  final imageAspect = imageNativeSize.width / imageNativeSize.height;
  final screenAspect = screenSize.width / screenSize.height;
  return imageAspect > screenAspect;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/ui/crop_math_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/crop_math.dart test/ui/crop_math_test.dart
git commit -m "feat: add calculateCropRect pure function with unit tests"
```

---

### Task 5: Home Screen Full Rewrite

**Files:**
- Modify: `lib/ui/screens/home_screen.dart`

This is the largest task. Rewrites `_ArtworkDisplay` into a `ConsumerStatefulWidget` with full-bleed layout, metadata overlay, SAVE toggle, and crop mode. Replaces the old `CustomScrollView` layout entirely.

> Build frequently as you go — the file is large. The existing `HomeScreen` shell (navigation bar, `IndexedStack`) stays unchanged.

- [ ] **Step 1: Add imports at top of `home_screen.dart`**

Replace the existing import block with:

```dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/artwork.dart' as model;
import '../../models/artwork_data.dart';
import '../../state/app_state.dart';
import '../../ui/crop_math.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
```

- [ ] **Step 2: Rewrite `_ArtworkDisplay` as `ConsumerStatefulWidget`**

Replace the entire `_ArtworkDisplay` class (from `class _ArtworkDisplay` down to the end of the `_ActionButton`/`_RefreshButton` classes) with the following:

```dart
// ══════════════════════════════════════════════════
// Artwork display — full-bleed with overlay + crop
// ══════════════════════════════════════════════════

class _ArtworkDisplay extends ConsumerStatefulWidget {
  final model.Artwork artwork;

  const _ArtworkDisplay({required this.artwork});

  @override
  ConsumerState<_ArtworkDisplay> createState() => _ArtworkDisplayState();
}

class _ArtworkDisplayState extends ConsumerState<_ArtworkDisplay> {
  bool _overlayVisible = true;
  Timer? _dismissTimer;
  bool _cropMode = false;
  double _panOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _showOverlay();
  }

  @override
  void didUpdateWidget(_ArtworkDisplay old) {
    super.didUpdateWidget(old);
    // New artwork arrived — reset overlay and crop state
    if (old.artwork.contentId != widget.artwork.contentId) {
      _dismissTimer?.cancel();
      setState(() {
        _cropMode = false;
        _panOffset = 0.0;
        _overlayVisible = true;
      });
      _showOverlay();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    setState(() => _overlayVisible = true);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), _hideOverlay);
  }

  void _hideOverlay() {
    if (mounted) setState(() => _overlayVisible = false);
  }

  void _toggleOverlay() {
    if (_overlayVisible) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildImageArea(context)),
        _buildActionColumn(context),
      ],
    );
  }

  // ── Image area (Stack: image + overlay + crop) ──

  Widget _buildImageArea(BuildContext context) {
    final artwork = widget.artwork;
    final imageProvider = artwork.localPath != null &&
            File(artwork.localPath!).existsSync()
        ? FileImage(File(artwork.localPath!)) as ImageProvider
        : NetworkImage(artwork.image);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base image
          GestureDetector(
            onTap: _cropMode ? null : _toggleOverlay,
            child: ColorFiltered(
              colorFilter: _cropMode
                  ? const ColorFilter.mode(
                      Color(0x80000000), BlendMode.darken)
                  : const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply),
              child: CachedNetworkImage(
                imageUrl: artwork.image,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Color(0xFF111111)),
                errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1A0000)),
              ),
            ),
          ),

          // Metadata overlay (hidden during crop mode)
          if (!_cropMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _overlayVisible ? 1.0 : 0.0,
                child: _MetadataOverlay(artwork: artwork),
              ),
            ),

          // Crop overlay (shown during crop mode)
          if (_cropMode) ...[
            Positioned.fill(
              child: _CropOverlay(
                panOffset: _panOffset,
                imageAspectRatio: artwork.width != null && artwork.height != null
                    ? artwork.width! / artwork.height!
                    : 1.0,
                screenSize: MediaQuery.of(context).size,
              ),
            ),
            // Slider (only if image is wider than screen)
            if (needsPanSlider(
              imageNativeSize: Size(
                (artwork.width ?? 1).toDouble(),
                (artwork.height ?? 1).toDouble(),
              ),
              screenSize: MediaQuery.of(context).size,
            ))
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbColor: Colors.white,
                    activeTrackColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    overlayColor: Colors.white24,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _panOffset,
                    onChanged: (v) => setState(() => _panOffset = v),
                  ),
                ),
              ),
            // Cancel / Apply buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _cancelCrop,
                    icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                    label: const Text('CANCEL',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                  const SizedBox(width: 24),
                  FilledButton.icon(
                    onPressed: () => _applyCrop(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('APPLY', style: TextStyle(fontSize: 11)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Right action column ──

  Widget _buildActionColumn(BuildContext context) {
    final artwork = widget.artwork;
    final isFavAsync = ref.watch(isFavoriteProvider(artwork.contentId));
    final isFav = isFavAsync.valueOrNull ?? false;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // NEW
          _ColumnIconButton(
            icon: Icons.refresh,
            onTap: () => ref
                .read(currentArtworkProvider.notifier)
                .refresh(setWallpaper: false),
          ),
          // SAVE
          _ColumnIconButton(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            active: isFav,
            onTap: () async {
              final db = ref.read(databaseProvider);
              if (isFav) {
                await db.removeFavorite(artwork.contentId);
              } else {
                await db.addFavorite(artwork.contentId);
              }
            },
          ),
          // SET
          _ColumnIconButton(
            icon: Icons.wallpaper,
            onTap: () {
              if (artwork.localPath == null) return;
              setState(() {
                _cropMode = true;
                _panOffset = 0.0;
                _overlayVisible = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── Crop actions ──

  void _cancelCrop() {
    setState(() {
      _cropMode = false;
      _panOffset = 0.0;
    });
    _showOverlay();
  }

  Future<void> _applyCrop(BuildContext context) async {
    final artwork = widget.artwork;
    if (artwork.localPath == null) return;

    final screenSize = MediaQuery.of(context).size;
    final file = File(artwork.localPath!);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final cropRect = calculateCropRect(
      imageNativeSize: Size(
        srcImage.width.toDouble(),
        srcImage.height.toDouble(),
      ),
      screenSize: screenSize,
      panOffset: _panOffset,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      srcImage,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      Paint(),
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(
      cropRect.width.round(),
      cropRect.height.round(),
    );
    final pngBytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) return;

    final tmp = await getTemporaryDirectory();
    final croppedPath = '${tmp.path}/ziba_crop_${artwork.contentId}.png';
    await File(croppedPath).writeAsBytes(pngBytes.buffer.asUint8List());

    final adapter = ref.read(wallpaperAdapterProvider);
    await adapter.setWallpaper(croppedPath);

    if (mounted) {
      setState(() {
        _cropMode = false;
        _panOffset = 0.0;
      });
    }
  }
}

// ══════════════════════════════════════════════════
// Metadata overlay
// ══════════════════════════════════════════════════

class _MetadataOverlay extends StatelessWidget {
  final model.Artwork artwork;

  const _MetadataOverlay({required this.artwork});

  @override
  Widget build(BuildContext context) {
    final year = artwork.yearAsString ?? artwork.completitionYear?.toString();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
          colors: [Colors.transparent, Color(0xBF000000)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            artwork.title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artwork.artistName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (year != null) ...[
            const SizedBox(height: 2),
            Text(
              year,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Crop overlay painter
// ══════════════════════════════════════════════════

class _CropOverlay extends StatelessWidget {
  final double panOffset;
  final double imageAspectRatio;
  final Size screenSize;

  const _CropOverlay({
    required this.panOffset,
    required this.imageAspectRatio,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CropPainter(
        panOffset: panOffset,
        screenAspectRatio: screenSize.width / screenSize.height,
        imageAspectRatio: imageAspectRatio,
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final double panOffset;
  final double screenAspectRatio;
  final double imageAspectRatio;

  _CropPainter({
    required this.panOffset,
    required this.screenAspectRatio,
    required this.imageAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rendered image width fills `size`. Calculate box width in render space.
    final boxWidth = (size.height * screenAspectRatio).clamp(0.0, size.width);
    final maxLeft = size.width - boxWidth;
    final boxLeft = maxLeft * panOffset;
    final boxRect = Rect.fromLTWH(boxLeft, 0, boxWidth, size.height);

    final maskPaint = Paint()..color = const Color(0x80000000);
    // Left mask
    if (boxLeft > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, boxLeft, size.height), maskPaint);
    }
    // Right mask
    final rightStart = boxLeft + boxWidth;
    if (rightStart < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(rightStart, 0, size.width - rightStart, size.height),
        maskPaint,
      );
    }
    // Selection border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(boxRect, borderPaint);
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.panOffset != panOffset ||
      old.screenAspectRatio != screenAspectRatio ||
      old.imageAspectRatio != imageAspectRatio;
}

// ══════════════════════════════════════════════════
// Action column icon button
// ══════════════════════════════════════════════════

class _ColumnIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ColumnIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        icon: Icon(icon),
        iconSize: 22,
        color: active ? Colors.white : Colors.white38,
        onPressed: onTap,
        tooltip: null,
        splashRadius: 22,
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Refresh button (error state)
// ══════════════════════════════════════════════════

class _RefreshButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        ref
            .read(currentArtworkProvider.notifier)
            .refresh(setWallpaper: false);
      },
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('TRY AGAIN'),
    );
  }
}
```

Also update `_ArtworkView` to pass `ArtworkData` properly and update `_EmptyState` call:

In `_EmptyState.build`, update the button:
```dart
FilledButton.icon(
  onPressed: () {
    ref.read(currentArtworkProvider.notifier).refresh(setWallpaper: false);
  },
  ...
)
```

And update `_ArtworkView.data` callback:
```dart
data: (artwork) {
  if (artwork == null) return _EmptyState();
  return _ArtworkDisplay(artwork: artwork);
},
```

- [ ] **Step 3: Build check**

```bash
flutter build macos --debug 2>&1 | tail -20
```

Expected: `Build succeeded.` Fix any type errors before proceeding.

- [ ] **Step 4: Smoke test**

Run the app and verify:
1. App opens — full-bleed image fills area left of action column
2. Metadata overlay appears, auto-fades after 5s
3. Tapping image toggles overlay
4. NEW button fetches new artwork without changing wallpaper
5. SAVE button fills/empties heart icon
6. SET button enters crop mode — dark overlay + crop border + Cancel/Apply

- [ ] **Step 5: Commit**

```bash
git add lib/ui/screens/home_screen.dart lib/ui/crop_math.dart
git commit -m "feat: rewrite home screen — full-bleed layout, metadata overlay, SAVE toggle, crop picker"
```

---

### Task 6: ArtworkDetailScreen

**Files:**
- Create: `lib/ui/screens/artwork_detail_screen.dart`

Full-bleed image from Favorites, same metadata fade behavior, SET (crop) + REMOVE bottom-right buttons.

- [ ] **Step 1: Create `lib/ui/screens/artwork_detail_screen.dart`**

```dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/artwork_data.dart';
import '../../state/app_state.dart';
import '../../ui/crop_math.dart';

class ArtworkDetailScreen extends ConsumerStatefulWidget {
  final ArtworkData artwork;

  const ArtworkDetailScreen({super.key, required this.artwork});

  @override
  ConsumerState<ArtworkDetailScreen> createState() =>
      _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends ConsumerState<ArtworkDetailScreen> {
  bool _overlayVisible = true;
  Timer? _dismissTimer;
  bool _cropMode = false;
  double _panOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _showOverlay();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    setState(() => _overlayVisible = true);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), _hideOverlay);
  }

  void _hideOverlay() {
    if (mounted) setState(() => _overlayVisible = false);
  }

  void _toggleOverlay() {
    if (_overlayVisible) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed image
          GestureDetector(
            onTap: _cropMode ? null : _toggleOverlay,
            child: _buildImage(),
          ),

          // Metadata overlay
          if (!_cropMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _overlayVisible ? 1.0 : 0.0,
                child: _DetailMetadataOverlay(artwork: widget.artwork),
              ),
            ),

          // Crop overlay
          if (_cropMode) ...[
            Positioned.fill(
              child: _DetailCropOverlay(
                panOffset: _panOffset,
                artwork: widget.artwork,
                screenSize: MediaQuery.of(context).size,
              ),
            ),
            if (needsPanSlider(
              imageNativeSize: Size(
                (widget.artwork.width ?? 1).toDouble(),
                (widget.artwork.height ?? 1).toDouble(),
              ),
              screenSize: MediaQuery.of(context).size,
            ))
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbColor: Colors.white,
                    activeTrackColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _panOffset,
                    onChanged: (v) => setState(() => _panOffset = v),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _cancelCrop,
                    icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                    label: const Text('CANCEL',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                  const SizedBox(width: 24),
                  FilledButton.icon(
                    onPressed: () => _applyCrop(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('APPLY', style: TextStyle(fontSize: 11)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // SET + REMOVE overlay buttons (bottom-right)
          if (!_cropMode)
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayIconButton(
                    icon: Icons.wallpaper,
                    onTap: () {
                      setState(() {
                        _cropMode = true;
                        _panOffset = 0.0;
                        _overlayVisible = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _OverlayIconButton(
                    icon: Icons.delete_outline,
                    onTap: () => _removeAndPop(context),
                  ),
                ],
              ),
            ),

          // Back button (top-left)
          if (!_cropMode)
            Positioned(
              top: 16,
              left: 16,
              child: _OverlayIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final artwork = widget.artwork;
    final localPath = artwork.localPath;

    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return CachedNetworkImage(
      imageUrl: artwork.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF111111)),
      errorWidget: (_, __, ___) =>
          const ColoredBox(color: Color(0xFF1A0000)),
    );
  }

  void _cancelCrop() {
    setState(() {
      _cropMode = false;
      _panOffset = 0.0;
    });
    _showOverlay();
  }

  Future<void> _applyCrop(BuildContext context) async {
    final artwork = widget.artwork;
    final localPath = artwork.localPath;
    if (localPath == null || !File(localPath).existsSync()) return;

    final screenSize = MediaQuery.of(context).size;
    final bytes = await File(localPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final cropRect = calculateCropRect(
      imageNativeSize: Size(
          srcImage.width.toDouble(), srcImage.height.toDouble()),
      screenSize: screenSize,
      panOffset: _panOffset,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      srcImage,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      Paint(),
    );
    final cropped = await recorder
        .endRecording()
        .toImage(cropRect.width.round(), cropRect.height.round());
    final pngBytes =
        await cropped.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) return;

    final tmp = await getTemporaryDirectory();
    final croppedPath =
        '${tmp.path}/ziba_crop_${artwork.contentId}.png';
    await File(croppedPath)
        .writeAsBytes(pngBytes.buffer.asUint8List());

    final adapter = ref.read(wallpaperAdapterProvider);
    await adapter.setWallpaper(croppedPath);

    if (mounted) {
      setState(() {
        _cropMode = false;
        _panOffset = 0.0;
      });
    }
  }

  Future<void> _removeAndPop(BuildContext context) async {
    final artwork = widget.artwork;
    final db = ref.read(databaseProvider);
    await db.removeFavorite(artwork.contentId);

    final localPath = artwork.localPath;
    if (localPath != null && File(localPath).existsSync()) {
      File(localPath).deleteSync();
    }

    if (context.mounted) Navigator.of(context).pop();
  }
}

// ══════════════════════════════════════════════════
// Metadata overlay (detail screen variant)
// ══════════════════════════════════════════════════

class _DetailMetadataOverlay extends StatelessWidget {
  final ArtworkData artwork;

  const _DetailMetadataOverlay({required this.artwork});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xBF000000)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 80, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            artwork.title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            artwork.artistName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (artwork.completitionYear != null) ...[
            const SizedBox(height: 2),
            Text(
              artwork.completitionYear.toString(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Detail crop overlay
// ══════════════════════════════════════════════════

class _DetailCropOverlay extends StatelessWidget {
  final double panOffset;
  final ArtworkData artwork;
  final Size screenSize;

  const _DetailCropOverlay({
    required this.panOffset,
    required this.artwork,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetailCropPainter(
        panOffset: panOffset,
        screenAspectRatio: screenSize.width / screenSize.height,
      ),
    );
  }
}

class _DetailCropPainter extends CustomPainter {
  final double panOffset;
  final double screenAspectRatio;

  _DetailCropPainter({
    required this.panOffset,
    required this.screenAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxWidth =
        (size.height * screenAspectRatio).clamp(0.0, size.width);
    final maxLeft = size.width - boxWidth;
    final boxLeft = maxLeft * panOffset;

    final maskPaint = Paint()..color = const Color(0x80000000);
    if (boxLeft > 0) {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, boxLeft, size.height), maskPaint);
    }
    final rightStart = boxLeft + boxWidth;
    if (rightStart < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(rightStart, 0, size.width - rightStart, size.height),
        maskPaint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, 0, boxWidth, size.height),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DetailCropPainter old) =>
      old.panOffset != panOffset ||
      old.screenAspectRatio != screenAspectRatio;
}

// ══════════════════════════════════════════════════
// Overlay icon button
// ══════════════════════════════════════════════════

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Build check**

```bash
flutter build macos --debug 2>&1 | tail -10
```

Expected: `Build succeeded.`

- [ ] **Step 3: Commit**

```bash
git add lib/ui/screens/artwork_detail_screen.dart
git commit -m "feat: add ArtworkDetailScreen with full-bleed image, SET crop, and REMOVE"
```

---

### Task 7: FavoritesScreen Tap Navigation

**Files:**
- Modify: `lib/ui/screens/favorites_screen.dart`

Tap card → `ArtworkDetailScreen`. Long-press remove → moved to the detail screen; remove from card.

- [ ] **Step 1: Add imports to `favorites_screen.dart`**

Add at top:
```dart
import '../../models/artwork_data.dart';
import 'artwork_detail_screen.dart';
```

- [ ] **Step 2: Rewrite `_FavoriteCard.build` to navigate on tap**

Replace `GestureDetector` in `_FavoriteCard`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final favoritesAsync = ref.watch(favoritesProvider);

  // Build ArtworkData from the favorites list by contentId
  final artworkData = ArtworkData(
    contentId: contentId,
    title: title,
    artist: artist,   // Note: _FavoriteCard has title and artist fields
    artistName: artist,
    imageUrl: imageUrl,
  );
```

Wait — `_FavoriteCard` only has `imageUrl`, `title`, `artist` (not `artistName`), and `contentId`. We need the full row to build `ArtworkData`. The simplest fix: change `_FavoriteCard` to accept `ArtworkData` directly.

Update `FavoritesScreen.data` builder to convert rows:
```dart
data: (items) {
  // items is List<Artwork> (Drift row)
  ...
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      final artworkData = ArtworkData.fromRow(items[index]);
      return _FavoriteCard(artwork: artworkData);
    },
    childCount: items.length,
  ),
```

Replace `_FavoriteCard` with:
```dart
class _FavoriteCard extends StatelessWidget {
  final ArtworkData artwork;

  const _FavoriteCard({required this.artwork});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtworkDetailScreen(artwork: artwork),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: artwork.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: theme.colorScheme.errorContainer,
                  child: const Icon(Icons.broken_image, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artwork.title,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            artwork.artistName,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Build check**

```bash
flutter build macos --debug 2>&1 | tail -10
```

Expected: `Build succeeded.`

- [ ] **Step 4: Smoke test**

Run app, go to SAVED tab, tap a card — detail screen should open with full image, SET + REMOVE buttons. REMOVE should delete from favorites and pop back.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/screens/favorites_screen.dart
git commit -m "feat: tap favorites card navigates to ArtworkDetailScreen"
```

---

## Self-Review Against Spec

| Spec requirement | Covered in |
|---|---|
| Full-bleed layout, no-scroll, right action column (64pt) | Task 5 |
| NEW calls `refresh(setWallpaper: false)` | Task 3 |
| SAVE toggles heart, reads `isFavoriteProvider` | Task 5 |
| SET opens crop picker (always) | Task 5 |
| Metadata overlay: fade in, 5s auto-fade, tap-to-toggle | Task 5 |
| Crop picker: screen-ratio box, pan slider, Cancel/Apply | Task 5 |
| `dart:ui` crop → PNG → setWallpaper | Task 5 |
| Small caps on all body/label/appbar styles | Task 1 |
| `ArtworkData` value object | Task 2 |
| `ArtworkDetailScreen`: full-bleed, SET + REMOVE | Task 6 |
| REMOVE: deletes DB row + local file, pops | Task 6 |
| FavoritesScreen tap → detail nav | Task 7 |
| Window size (already done) | — |
| `addToHistory` fix (already done) | — |
| No new packages | Tasks use `dart:ui`, already in Flutter |

All spec requirements covered. No placeholders.
