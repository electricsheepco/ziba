import 'dart:async';
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

  Widget _buildImageArea(BuildContext context) {
    final artwork = widget.artwork;
    final screenSize = MediaQuery.of(context).size;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
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
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFF111111)),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF1A0000)),
              ),
            ),
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
                child: _MetadataOverlay(artwork: artwork),
              ),
            ),

          // Crop overlay
          if (_cropMode) ...[
            Positioned.fill(
              child: CustomPaint(
                painter: _CropPainter(
                  panOffset: _panOffset,
                  screenAspectRatio: screenSize.width / screenSize.height,
                ),
              ),
            ),
            if (needsPanSlider(
              imageNativeSize: Size(
                (artwork.width ?? 1).toDouble(),
                (artwork.height ?? 1).toDouble(),
              ),
              screenSize: screenSize,
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
                            color: Colors.white70, fontSize: 11)),
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
    );
  }

  Widget _buildActionColumn(BuildContext context) {
    final artwork = widget.artwork;
    final isFavAsync = ref.watch(isFavoriteProvider(artwork.contentId));
    final isFav = isFavAsync.valueOrNull ?? false;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ColumnIconButton(
            icon: Icons.refresh,
            onTap: () => ref
                .read(currentArtworkProvider.notifier)
                .refresh(setWallpaper: false),
          ),
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
          _ColumnIconButton(
            icon: Icons.wallpaper,
            onTap: () {
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

  void _cancelCrop() {
    setState(() {
      _cropMode = false;
      _panOffset = 0.0;
    });
    _showOverlay();
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
// Metadata overlay
// ══════════════════════════════════════════════════

class _MetadataOverlay extends StatelessWidget {
  final model.Artwork artwork;

  const _MetadataOverlay({required this.artwork});

  @override
  Widget build(BuildContext context) {
    final year =
        artwork.yearAsString ?? artwork.completitionYear?.toString();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
        splashRadius: 22,
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
