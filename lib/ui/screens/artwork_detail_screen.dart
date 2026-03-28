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
              child: CustomPaint(
                painter: _DetailCropPainter(
                  panOffset: _panOffset,
                  screenAspectRatio: MediaQuery.of(context).size.width /
                      MediaQuery.of(context).size.height,
                ),
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

          // SET + REMOVE (bottom-right, hidden during crop)
          if (!_cropMode)
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayIconButton(
                    icon: Icons.wallpaper,
                    onTap: () => setState(() {
                      _cropMode = true;
                      _panOffset = 0.0;
                      _overlayVisible = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _OverlayIconButton(
                    icon: Icons.delete_outline,
                    onTap: () => _removeAndPop(context),
                  ),
                ],
              ),
            ),

          // Back (top-left, hidden during crop)
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
    final screenSize = MediaQuery.of(context).size;

    // Resolve local path — download if needed (cached, fast)
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
      // Right padding wider to avoid overlap with SET/REMOVE buttons
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
// Crop painter
// ══════════════════════════════════════════════════

class _DetailCropPainter extends CustomPainter {
  final double panOffset;
  final double screenAspectRatio;

  _DetailCropPainter(
      {required this.panOffset, required this.screenAspectRatio});

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
  bool shouldRepaint(_DetailCropPainter old) =>
      old.panOffset != panOffset ||
      old.screenAspectRatio != screenAspectRatio;
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
