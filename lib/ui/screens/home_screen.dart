import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/artwork.dart' as model;
import '../../state/app_state.dart';
import '../../data/database.dart' show Artwork;
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
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(activeTabProvider);
    return Scaffold(
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
              Text(e.toString(), style: theme.textTheme.bodyMedium),
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

  @override
  void didUpdateWidget(_ArtworkDisplay old) {
    super.didUpdateWidget(old);
    if (old.artwork.contentId != widget.artwork.contentId) {
      setState(() {
        _cropMode = false;
        _panOffset = 0.0;
      });
    }
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

    return CustomScrollView(
      slivers: [
        // Image card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio:
                        (artwork.width ?? 16) / (artwork.height ?? 9),
                    child: CachedNetworkImage(
                      imageUrl: artwork.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 1),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.errorContainer,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  // Metadata overlay — always visible at bottom of image
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
                            colors: [
                              Colors.transparent,
                              Color(0xCC000000),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (artwork.style != null)
                              Text(
                                artwork.style!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B8EC4),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (artwork.style != null)
                              const SizedBox(height: 4),
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

                  // Crop zone preview — shows which region will become wallpaper
                  if (showSlider)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropPainter(
                          panOffset: _panOffset,
                          screenAspectRatio:
                              displaySize.width / displaySize.height,
                          preview: !_cropMode,
                        ),
                      ),
                    ),

                  // Crop mode: dark tint to signal "selecting crop"
                  if (_cropMode)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropPainter(
                          panOffset: _panOffset,
                          screenAspectRatio:
                              displaySize.width / displaySize.height,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.crop, size: 12,
                          color: Color(0xFF6B8EC4)),
                      const SizedBox(width: 6),
                      Text(
                        'WALLPAPER CROP',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
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
          ),

        // Actions + extra metadata chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (artwork.style != null)
                      _MetaChip(label: artwork.style!),
                    if (artwork.genre != null)
                      _MetaChip(label: artwork.genre!),
                    if (artwork.technique != null)
                      _MetaChip(label: artwork.technique!),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.refresh,
                      label: 'NEW',
                      onTap: () => ref
                          .read(currentArtworkProvider.notifier)
                          .refresh(setWallpaper: false),
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      icon: isFav
                          ? Icons.favorite
                          : Icons.favorite_border,
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
                    const SizedBox(width: 12),
                    _ActionButton(
                      icon: Icons.wallpaper,
                      label: 'SET WALLPAPER',
                      onTap: () {
                        if (showSlider) {
                          // Wide image — show crop selector
                          setState(() => _cropMode = true);
                        } else {
                          // Fits screen — set directly
                          _applyCrop(context);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
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
    final croppedPath = '${tmp.path}/ziba_crop_${artwork.contentId}.png';
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
