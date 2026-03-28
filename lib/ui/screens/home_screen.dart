import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ArtworkView(),
          HistoryScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
    final showSlider = needsPanSlider(
      imageNativeSize: Size(
        (artwork.width ?? 1).toDouble(),
        (artwork.height ?? 1).toDouble(),
      ),
      screenSize: screenSize,
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
                  // Crop overlay
                  if (_cropMode) ...[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropPainter(
                          panOffset: _panOffset,
                          screenAspectRatio:
                              screenSize.width / screenSize.height,
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
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.white70),
                            label: const Text('CANCEL',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                          ),
                          const SizedBox(width: 24),
                          FilledButton.icon(
                            onPressed: () => _applyCrop(context),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('APPLY',
                                style: TextStyle(fontSize: 11)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Pan slider — shown below image for wide artworks
        if (showSlider)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: Colors.white,
                  activeTrackColor: Colors.white70,
                  inactiveTrackColor: Colors.white24,
                  overlayColor: Colors.white24,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: _panOffset,
                  onChanged: (v) => setState(() => _panOffset = v),
                ),
              ),
            ),
          ),

        // Metadata + actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(artwork.title,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(artwork.artistName,
                    style: theme.textTheme.bodyLarge),
                if (year != null) ...[
                  const SizedBox(height: 4),
                  Text(year, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
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
                      onTap: () => setState(() {
                        _cropMode = true;
                        _panOffset = 0.0;
                      }),
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
    final screenSize = MediaQuery.of(context).size;

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
      setState(() {
        _cropMode = false;
        _panOffset = 0.0;
      });
    }
  }
}


// ══════════════════════════════════════════════════
// Crop overlay painter
// ══════════════════════════════════════════════════

class _CropPainter extends CustomPainter {
  final double panOffset;
  final double screenAspectRatio;

  _CropPainter({required this.panOffset, required this.screenAspectRatio});

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
        Rect.fromLTWH(
            rightStart, 0, size.width - rightStart, size.height),
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
  bool shouldRepaint(_CropPainter old) =>
      old.panOffset != panOffset ||
      old.screenAspectRatio != screenAspectRatio;
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
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16,
          color: active ? theme.colorScheme.primary : null),
      label: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: active ? theme.colorScheme.primary : null)),
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: 1,
        ),
      ),
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
