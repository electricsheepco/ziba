import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/artwork.dart' as model;
import '../../state/app_state.dart';
import '../../ui/crop_math.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the auto-rotation timer alive for the full app session.
    ref.watch(autoRotateTimerProvider);
    final currentIndex = ref.watch(activeTabProvider);
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            currentIndex != 0) {
          ref.read(activeTabProvider.notifier).state = 0;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          _ArtworkView(),
          HistoryScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) =>
            ref.read(activeTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'TODAY',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'HISTORY',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'SAVED',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'SETTINGS',
          ),
        ],
      ),
    ),  // Focus
    );
  }
}

// ══════════════════════════════════════════════════
// Main artwork view
// ══════════════════════════════════════════════════

class _ArtworkView extends ConsumerWidget {
  const _ArtworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworkAsync = ref.watch(currentArtworkProvider);
    final theme = Theme.of(context);

    return artworkAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 1),
            SizedBox(height: 16),
            Text('Fetching artwork...'),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load artwork', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                "Couldn't reach WikiArt. Check your connection and try again.",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _RefreshButton(),
            ],
          ),
        ),
      ),
      data: (artwork) {
        if (artwork == null) return _EmptyState();
        return _ArtworkDisplay(artwork: artwork);
      },
    );
  }
}

// ══════════════════════════════════════════════════
// Empty state (first launch)
// ══════════════════════════════════════════════════

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ZIBA',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 6,
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your screen.\nTheir masterpiece.',
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => ref
                  .read(currentArtworkProvider.notifier)
                  .refresh(setWallpaper: false),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('GET FIRST ARTWORK'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Artwork display — full-bleed with right action column
// ══════════════════════════════════════════════════

class _ArtworkDisplay extends ConsumerStatefulWidget {
  final model.Artwork artwork;

  const _ArtworkDisplay({required this.artwork});

  @override
  ConsumerState<_ArtworkDisplay> createState() => _ArtworkDisplayState();
}

class _ArtworkDisplayState extends ConsumerState<_ArtworkDisplay> {
  bool _cropMode = false;
  double _panOffset = 0.0;
  // null = slider hidden; 0.0–1.0 = dim amount
  double? _dimLevel;
  // null = slider hidden; -1.0 (cool) to +1.0 (warm)
  double? _toneLevel;

  @override
  void didUpdateWidget(_ArtworkDisplay old) {
    super.didUpdateWidget(old);
    if (old.artwork.contentId != widget.artwork.contentId) {
      setState(() {
        _cropMode = false;
        _panOffset = 0.0;
        _dimLevel = null;
        _toneLevel = null;
      });
    }
  }

  /// Returns the colour to overlay for the current tone level, used both
  /// for the live preview on the card and for baking into the wallpaper.
  Color _toneColor(double t) {
    if (t == 0) return Colors.transparent;
    final opacity = t.abs() * 0.28; // max ~28 % tint
    return t > 0
        ? const Color(0xFFFF9933).withValues(alpha: opacity) // warm amber
        : const Color(0xFF6699FF).withValues(alpha: opacity); // cool blue
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isFavAsync = ref.watch(isFavoriteProvider(artwork.contentId));
    final isFav = isFavAsync.valueOrNull ?? false;
    final year = artwork.yearAsString ?? artwork.completitionYear?.toString();
    // Use actual display resolution so the slider only appears for images
    // that are genuinely wider than the user's monitor(s).
    final display = ui.PlatformDispatcher.instance.displays.firstOrNull;
    final displaySize = display != null
        ? Size(display.size.width / display.devicePixelRatio,
               display.size.height / display.devicePixelRatio)
        : screenSize;
    final showSlider = needsPanSlider(
      imageNativeSize: Size(
        (artwork.width ?? 1).toDouble(),
        (artwork.height ?? 1).toDouble(),
      ),
      screenSize: displaySize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image — expands to fill available height, no blank gap
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: artwork.image,
                    fit: BoxFit.cover,
                    // Pan the image when slider is active so the user sees
                    // which portion will be used as wallpaper.
                    alignment: showSlider
                        ? Alignment(_panOffset * 2 - 1, 0)
                        : Alignment.center,
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 1),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.errorContainer,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                  // Dim preview
                  if (_dimLevel != null && _dimLevel! > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          color: Colors.black.withValues(alpha: _dimLevel!),
                        ),
                      ),
                    ),
                  // Tone preview
                  if (_toneLevel != null && _toneLevel != 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          color: _toneColor(_toneLevel!),
                        ),
                      ),
                    ),
                  // Metadata overlay
                  if (!_cropMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (artwork.style != null) ...[
                              Text(
                                artwork.style!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B8EC4),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              artwork.title,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w300,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                artwork.artistName,
                                if (year != null) year,
                                if (artwork.style != null) artwork.style!,
                              ].join('  ·  '),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Crop zone painter — only in active crop mode
                  if (showSlider && _cropMode)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropPainter(
                          panOffset: _panOffset,
                          screenAspectRatio:
                              displaySize.width / displaySize.height,
                          preview: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Wallpaper crop selector — only for wide artworks
        if (showSlider)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.crop, size: 12, color: Color(0xFF6B8EC4)),
                    const SizedBox(width: 6),
                    Text(
                      'WALLPAPER CROP',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Listener(
                  // Trackpad two-finger horizontal scroll adjusts crop pan.
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      final dx = event.scrollDelta.dx;
                      final dy = event.scrollDelta.dy;
                      if (dx.abs() > dy.abs() && dx.abs() > 0) {
                        setState(() {
                          _panOffset =
                              (_panOffset + dx / 300).clamp(0.0, 1.0);
                        });
                      }
                    }
                  },
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: const Color(0xFF6B8EC4),
                      activeTrackColor: const Color(0xFF6B8EC4),
                      inactiveTrackColor:
                          const Color(0xFF6B8EC4).withValues(alpha: 0.2),
                      overlayColor:
                          const Color(0xFF6B8EC4).withValues(alpha: 0.15),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _panOffset,
                      onChanged: (v) => setState(() => _panOffset = v),
                    ),
                  ),
                ),
                if (_cropMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: _cancelCrop,
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text('CANCEL',
                              style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => _applyCrop(context),
                          icon: const Icon(Icons.wallpaper, size: 14),
                          label: const Text('SET AS WALLPAPER',
                              style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6B8EC4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // Chips + action buttons — tight to bottom of image
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (artwork.style != null) _MetaChip(label: artwork.style!),
                  if (artwork.genre != null) _MetaChip(label: artwork.genre!),
                  if (artwork.technique != null)
                    _MetaChip(label: artwork.technique!),
                ],
              ),
              const SizedBox(height: 12),
              // GET / DIM / TONE / SAVE / SET
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.refresh,
                    label: 'GET',
                    onTap: () => ref
                        .read(currentArtworkProvider.notifier)
                        .refresh(setWallpaper: false),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.brightness_medium_outlined,
                    label: 'DIM',
                    active: _dimLevel != null,
                    onTap: () => setState(() {
                      _dimLevel = _dimLevel == null ? 0.3 : null;
                    }),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.thermostat_outlined,
                    label: 'TONE',
                    active: _toneLevel != null,
                    onTap: () => setState(() {
                      _toneLevel = _toneLevel == null ? 0.0 : null;
                    }),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: isFav ? Icons.favorite : Icons.favorite_border,
                    label: 'SAVE',
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
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.wallpaper,
                    label: 'SET',
                    onTap: () {
                      if (showSlider) {
                        setState(() => _cropMode = true);
                      } else {
                        _applyCrop(context);
                      }
                    },
                  ),
                ],
              ),

              // Dim slider
              if (_dimLevel != null) ...[
                const SizedBox(height: 8),
                _FilterSliderRow(
                  icon: Icons.brightness_medium_outlined,
                  label: 'DIM',
                  value: _dimLevel!,
                  min: 0,
                  max: 1,
                  onChanged: (v) => setState(() => _dimLevel = v),
                  theme: theme,
                ),
              ],

              // Tone slider — cool (-1) to warm (+1)
              if (_toneLevel != null) ...[
                const SizedBox(height: 8),
                _FilterSliderRow(
                  icon: Icons.thermostat_outlined,
                  label: 'COOL',
                  trailingLabel: 'WARM',
                  value: _toneLevel!,
                  min: -1,
                  max: 1,
                  onChanged: (v) => setState(() => _toneLevel = v),
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _cancelCrop() {
    setState(() {
      _cropMode = false;
      _panOffset = 0.0;
    });
  }

  Future<void> _applyCrop(BuildContext context) async {
    final artwork = widget.artwork;

    // Use the actual display resolution for the crop aspect ratio, not the
    // app window size. MediaQuery gives window size; on a Retina MacBook that
    // might be ~660×750 (portrait), causing extreme zoom when macOS stretches
    // the crop to fill a 2560×1600 desktop.
    final display = ui.PlatformDispatcher.instance.displays.firstOrNull;
    final screenSize = display != null
        ? Size(display.size.width / display.devicePixelRatio,
               display.size.height / display.devicePixelRatio)
        : MediaQuery.of(context).size;

    // downloadImage returns cached path if already on disk (fast path)
    final wikiArt = ref.read(wikiArtProvider);
    final localPath = await wikiArt.downloadImage(artwork);
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
    final destRect = Rect.fromLTWH(0, 0, cropRect.width, cropRect.height);
    canvas.drawImageRect(srcImage, cropRect, destRect, Paint());
    // Bake dim
    final dim = _dimLevel ?? 0;
    if (dim > 0) {
      canvas.drawRect(
        destRect,
        Paint()..color = Color.fromARGB((dim * 255).round(), 0, 0, 0),
      );
    }
    // Bake tone
    final tone = _toneLevel ?? 0;
    if (tone != 0) {
      canvas.drawRect(destRect, Paint()..color = _toneColor(tone));
    }
    final cropped = await recorder
        .endRecording()
        .toImage(cropRect.width.round(), cropRect.height.round());
    final pngBytes =
        await cropped.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) return;

    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final croppedPath = '${tmp.path}/ziba_crop_${artwork.contentId}_$ts.png';
    await File(croppedPath).writeAsBytes(pngBytes.buffer.asUint8List());

    final adapter = ref.read(wallpaperAdapterProvider);
    await adapter.setWallpaper(croppedPath);

    if (mounted) {
      // Keep _panOffset so the crop box stays where the user placed it
      setState(() => _cropMode = false);
    }
  }
}


// ══════════════════════════════════════════════════
// Crop overlay painter
// ══════════════════════════════════════════════════

class _CropPainter extends CustomPainter {
  final double panOffset;
  final double screenAspectRatio;
  // preview = true draws a light outline only; false = full dark mask + outline
  final bool preview;

  _CropPainter({
    required this.panOffset,
    required this.screenAspectRatio,
    this.preview = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxWidth =
        (size.height * screenAspectRatio).clamp(0.0, size.width);
    final maxLeft = size.width - boxWidth;
    final boxLeft = maxLeft * panOffset;

    if (!preview) {
      final maskPaint = Paint()..color = const Color(0x80000000);
      if (boxLeft > 0) {
        canvas.drawRect(
            Rect.fromLTWH(0, 0, boxLeft, size.height), maskPaint);
      }
    final rightStart = boxLeft + boxWidth;
    if (rightStart < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(
            rightStart, 0, size.width - rightStart, size.height),
        maskPaint,
      );
    }
    } // end !preview mask

    final rightStart = boxLeft + boxWidth;

    // Crop box outline — solid in crop mode, subtle in preview
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, 0, boxWidth, size.height),
      Paint()
        ..color = preview ? Colors.white54 : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = preview ? 1.0 : 1.5,
    );

    // Preview: dim the areas outside the crop box subtly
    if (preview) {
      final dimPaint = Paint()..color = const Color(0x40000000);
      if (boxLeft > 0) {
        canvas.drawRect(
            Rect.fromLTWH(0, 0, boxLeft, size.height), dimPaint);
      }
      if (rightStart < size.width) {
        canvas.drawRect(
          Rect.fromLTWH(rightStart, 0, size.width - rightStart, size.height),
          dimPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.panOffset != panOffset ||
      old.screenAspectRatio != screenAspectRatio ||
      old.preview != preview;
}

// ══════════════════════════════════════════════════
// Shared filter slider row (DIM / TONE)
// ══════════════════════════════════════════════════

class _FilterSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ThemeData theme;

  const _FilterSliderRow({
    required this.icon,
    required this.label,
    this.trailingLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 10,
      letterSpacing: 1.5,
    );
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF6B8EC4)),
        const SizedBox(width: 6),
        Text(
          label,
          style: labelStyle.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbColor: const Color(0xFF6B8EC4),
              activeTrackColor: const Color(0xFF6B8EC4),
              inactiveTrackColor:
                  const Color(0xFF6B8EC4).withValues(alpha: 0.2),
              overlayColor: const Color(0xFF6B8EC4).withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        if (trailingLabel != null)
          Text(
            trailingLabel!,
            style: labelStyle.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// Metadata chip (style / genre / technique)
// ══════════════════════════════════════════════════

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Action button (row below metadata)
// ══════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    const labelStyle = TextStyle(fontSize: 11);

    if (active) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: labelStyle),
        style: FilledButton.styleFrom(padding: padding),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: labelStyle),
      style: OutlinedButton.styleFrom(padding: padding),
    );
  }
}

// ══════════════════════════════════════════════════
// Refresh button (error state retry)
// ══════════════════════════════════════════════════

class _RefreshButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => ref
          .read(currentArtworkProvider.notifier)
          .refresh(setWallpaper: false),
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('TRY AGAIN'),
    );
  }
}
