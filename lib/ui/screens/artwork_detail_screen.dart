import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _cropMode = false;
  double _panOffset = 0.0;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;

    // Use actual display size for crop ratio — not window size
    final display = ui.PlatformDispatcher.instance.displays.firstOrNull;
    final displaySize = display != null
        ? Size(display.size.width / display.devicePixelRatio,
               display.size.height / display.devicePixelRatio)
        : MediaQuery.of(context).size;

    final showSlider = needsPanSlider(
      imageNativeSize: Size(
        (artwork.width ?? 1).toDouble(),
        (artwork.height ?? 1).toDouble(),
      ),
      screenSize: displaySize,
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed image
          _buildImage(),

          // Crop zone preview — always visible when wide image
          if (showSlider)
            Positioned.fill(
              child: CustomPaint(
                painter: _DetailCropPainter(
                  panOffset: _panOffset,
                  screenAspectRatio: displaySize.width / displaySize.height,
                  preview: !_cropMode,
                ),
              ),
            ),

          // Metadata overlay (hidden during crop mode)
          if (!_cropMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: showSlider ? 96 : 0,
              child: _DetailMetadataOverlay(artwork: artwork),
            ),

          // Wallpaper crop slider + Apply/Cancel
          if (showSlider)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.crop, size: 12,
                            color: Color(0xFF6B8EC4)),
                        const SizedBox(width: 6),
                        const Text(
                          'WALLPAPER CROP',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: Colors.white54,
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
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _cropMode = false),
                            icon: const Icon(Icons.close,
                                size: 14, color: Colors.white70),
                            label: const Text('CANCEL',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white70)),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => _applyCrop(context, displaySize),
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
                  ],
                ),
              ),
            ),

          // SET + REMOVE buttons (hidden during crop)
          if (!_cropMode)
            Positioned(
              bottom: showSlider ? 112 : 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayIconButton(
                    icon: Icons.wallpaper,
                    onTap: () {
                      if (showSlider) {
                        setState(() => _cropMode = true);
                      } else {
                        _applyCrop(context, displaySize);
                      }
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
    ),  // Focus
    );
  }

  Widget _buildImage() {
    final artwork = widget.artwork;
    final localPath = artwork.localPath;

    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return CachedNetworkImage(
      imageUrl: artwork.imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF111111)),
      errorWidget: (_, __, ___) =>
          const ColoredBox(color: Color(0xFF1A0000)),
    );
  }

  Future<void> _applyCrop(BuildContext context, Size displaySize) async {
    final artwork = widget.artwork;

    String localPath;
    if (artwork.localPath != null && File(artwork.localPath!).existsSync()) {
      localPath = artwork.localPath!;
    } else {
      final client = ref.read(wikiArtProvider);
      localPath = await client.downloadImageUrl(
          artwork.imageUrl, artwork.contentId);
    }

    final bytes = await File(localPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final cropRect = calculateCropRect(
      imageNativeSize: Size(
          srcImage.width.toDouble(), srcImage.height.toDouble()),
      screenSize: displaySize,
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
    await File(croppedPath).writeAsBytes(pngBytes.buffer.asUint8List());

    final adapter = ref.read(wallpaperAdapterProvider);
    await adapter.setWallpaper(croppedPath);

    // Keep _panOffset — don't reset so the crop box stays in place
    if (mounted) setState(() => _cropMode = false);
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
// Metadata overlay
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
              fontFamily: 'Georgia',
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w300,
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
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (artwork.completitionYear != null) ...[
            const SizedBox(height: 2),
            Text(
              artwork.completitionYear.toString(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Crop painter
// ══════════════════════════════════════════════════

class _DetailCropPainter extends CustomPainter {
  final double panOffset;
  final double screenAspectRatio;
  final bool preview;

  _DetailCropPainter({
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
    final rightStart = boxLeft + boxWidth;

    final dimOpacity = preview ? 0x40 : 0x80;
    final maskPaint = Paint()
      ..color = Color.fromARGB(dimOpacity, 0, 0, 0);

    if (boxLeft > 0) {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, boxLeft, size.height), maskPaint);
    }
    if (rightStart < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(rightStart, 0, size.width - rightStart, size.height),
        maskPaint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, 0, boxWidth, size.height),
      Paint()
        ..color = preview ? Colors.white54 : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = preview ? 1.0 : 1.5,
    );
  }

  @override
  bool shouldRepaint(_DetailCropPainter old) =>
      old.panOffset != panOffset ||
      old.screenAspectRatio != screenAspectRatio ||
      old.preview != preview;
}

// ══════════════════════════════════════════════════
// Circular overlay icon button
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
