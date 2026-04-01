import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
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

  /// Show a heart (SAVE) overlay button alongside SET.
  /// Pass true from History; false (default) from Saved.
  final bool showSaveButton;

  const ArtworkDetailScreen({
    super.key,
    required this.artwork,
    this.showSaveButton = false,
  });

  @override
  ConsumerState<ArtworkDetailScreen> createState() =>
      _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends ConsumerState<ArtworkDetailScreen> {
  bool _cropMode = false;
  bool _setMode = false; // shows DIM / TONE / SET panel
  double _panOffset = 0.0;
  double? _dimLevel;  // null = hidden; 0.0–1.0
  double? _toneLevel; // null = hidden; -1.0 (cool) to +1.0 (warm)
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Color _toneColor(double t) {
    if (t == 0) return Colors.transparent;
    final opacity = t.abs() * 0.28;
    return t > 0
        ? const Color(0xFFFF9933).withValues(alpha: opacity)
        : const Color(0xFF6699FF).withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;

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
          if (_cropMode) {
            setState(() => _cropMode = false);
          } else if (_setMode) {
            setState(() {
              _setMode = false;
              _dimLevel = null;
              _toneLevel = null;
            });
          } else {
            Navigator.of(context).pop();
          }
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
            _buildImage(showSlider),

            // Dim preview overlay
            if (_dimLevel != null && _dimLevel! > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    color: Colors.black.withValues(alpha: _dimLevel!),
                  ),
                ),
              ),

            // Tone preview overlay
            if (_toneLevel != null && _toneLevel != 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    color: _toneColor(_toneLevel!),
                  ),
                ),
              ),

            // Crop zone preview
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

            // Metadata overlay (hidden during crop or set mode)
            if (!_cropMode && !_setMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: showSlider ? 96 : 0,
                child: _DetailMetadataOverlay(artwork: artwork),
              ),

            // SET mode panel — DIM / TONE / SET AS WALLPAPER (animated slide-up)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: _setMode ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _setMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: _buildSetPanel(context, displaySize, showSlider),
                ),
              ),
            ),

            // Crop slider (non-set mode, wide images)
            if (!_setMode && showSlider)
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
                      _buildCropSlider(context),
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
                              onPressed: () =>
                                  _applyCrop(context, displaySize),
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

            // Action overlay buttons (hidden during set/crop mode)
            if (!_cropMode && !_setMode)
              Positioned(
                bottom: showSlider ? 112 : 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showSaveButton) ...[
                      _SaveOverlayButton(contentId: widget.artwork.contentId),
                      const SizedBox(width: 8),
                    ],
                    _OverlayIconButton(
                      icon: Icons.wallpaper,
                      tooltip: 'Set as wallpaper',
                      onTap: () => setState(() => _setMode = true),
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
                tooltip: 'Back',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPanel(
      BuildContext context, Size displaySize, bool showSlider) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row + action buttons
          Row(
            children: [
              _PanelButton(
                icon: Icons.brightness_medium_outlined,
                label: 'DIM',
                active: _dimLevel != null,
                onTap: () => setState(() {
                  _dimLevel = _dimLevel == null ? 0.3 : null;
                }),
              ),
              const SizedBox(width: 10),
              _PanelButton(
                icon: Icons.thermostat_outlined,
                label: 'TONE',
                active: _toneLevel != null,
                onTap: () => setState(() {
                  _toneLevel = _toneLevel == null ? 0.0 : null;
                }),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  _setMode = false;
                  _dimLevel = null;
                  _toneLevel = null;
                }),
                icon: const Icon(Icons.close, size: 14, color: Colors.white70),
                label: const Text('CANCEL',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _setMode = false);
                  if (showSlider) {
                    setState(() => _cropMode = true);
                  } else {
                    _applyCrop(context, displaySize);
                  }
                },
                icon: const Icon(Icons.wallpaper, size: 14),
                label: const Text('SET', style: TextStyle(fontSize: 11)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8EC4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),

          // DIM slider
          if (_dimLevel != null) ...[
            const SizedBox(height: 8),
            _DetailFilterSliderRow(
              icon: Icons.brightness_medium_outlined,
              label: 'DIM',
              value: _dimLevel!,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _dimLevel = v),
            ),
          ],

          // TONE slider
          if (_toneLevel != null) ...[
            const SizedBox(height: 8),
            _DetailFilterSliderRow(
              icon: Icons.thermostat_outlined,
              label: 'COOL',
              trailingLabel: 'WARM',
              value: _toneLevel!,
              min: -1,
              max: 1,
              onChanged: (v) => setState(() => _toneLevel = v),
            ),
          ],

          // Crop slider (wide images)
          if (showSlider) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.crop, size: 12, color: Color(0xFF6B8EC4)),
                const SizedBox(width: 6),
                const Text(
                  'CROP',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            _buildCropSlider(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCropSlider(BuildContext context) {
    return Listener(
      // Trackpad two-finger horizontal scroll adjusts crop pan.
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final dx = event.scrollDelta.dx;
          final dy = event.scrollDelta.dy;
          if (dx.abs() > dy.abs() && dx.abs() > 0) {
            setState(() {
              _panOffset = (_panOffset + dx / 300).clamp(0.0, 1.0);
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
          overlayColor: const Color(0xFF6B8EC4).withValues(alpha: 0.15),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          trackHeight: 2,
        ),
        child: Slider(
          value: _panOffset,
          onChanged: (v) => setState(() => _panOffset = v),
        ),
      ),
    );
  }

  Widget _buildImage(bool showSlider) {
    final artwork = widget.artwork;
    final localPath = artwork.localPath;

    final alignment = (_cropMode || _setMode) && showSlider
        ? Alignment(_panOffset * 2 - 1, 0)
        : Alignment.center;

    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.contain,
        alignment: alignment,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return CachedNetworkImage(
      imageUrl: artwork.imageUrl,
      fit: BoxFit.contain,
      alignment: alignment,
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
    final croppedPath =
        '${tmp.path}/ziba_crop_${artwork.contentId}_$ts.png';
    await File(croppedPath).writeAsBytes(pngBytes.buffer.asUint8List());

    final adapter = ref.read(wallpaperAdapterProvider);
    await adapter.setWallpaper(croppedPath);

    if (mounted) setState(() => _cropMode = false);
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
          colors: [Colors.transparent, Color(0xCC000000)],
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
            [
              artwork.artistName,
              if (artwork.completitionYear != null)
                artwork.completitionYear.toString(),
              if (artwork.style != null) artwork.style!,
            ].join('  ·  '),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
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
    final maskPaint = Paint()..color = Color.fromARGB(dimOpacity, 0, 0, 0);

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
// Filter slider row (DIM / TONE)
// ══════════════════════════════════════════════════

class _DetailFilterSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _DetailFilterSliderRow({
    required this.icon,
    required this.label,
    this.trailingLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 10,
      letterSpacing: 1.5,
      color: Colors.white54,
    );
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF6B8EC4)),
        const SizedBox(width: 6),
        Text(label, style: labelStyle),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
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
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        if (trailingLabel != null)
          Text(trailingLabel!, style: labelStyle),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// Panel toggle button (DIM / TONE)
// ══════════════════════════════════════════════════

class _PanelButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<_PanelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const lapis = Color(0xFF6B8EC4);
    final fg = widget.active ? lapis : Colors.white54;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? lapis.withValues(alpha: _hovered ? 0.28 : 0.2)
                : Colors.white.withValues(alpha: _hovered ? 0.13 : 0.07),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.active
                  ? lapis
                  : (_hovered ? Colors.white38 : Colors.white24),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: fg),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Save overlay button (heart toggle, used from History)
// ══════════════════════════════════════════════════

class _SaveOverlayButton extends ConsumerWidget {
  final int contentId;
  const _SaveOverlayButton({required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(isFavoriteProvider(contentId));
    final isFav = isFavAsync.valueOrNull ?? false;

    return _OverlayIconButton(
      icon: isFav ? Icons.favorite : Icons.favorite_border,
      tooltip: isFav ? 'Remove from saved' : 'Save',
      onTap: () async {
        final db = ref.read(databaseProvider);
        if (isFav) {
          await db.removeFavorite(contentId);
        } else {
          await db.addFavorite(contentId);
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════
// Circular overlay icon button
// ══════════════════════════════════════════════════

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
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
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
