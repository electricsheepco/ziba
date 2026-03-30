import 'package:flutter/material.dart';
import 'girih_painter.dart';

enum ZibaLogoVariant { dark, light, markOnly }

/// Ziba brand lockup — ز mark + Girih field + ZIBA wordmark.
///
/// [size] is the base unit (ز font size). All other dimensions scale from it.
/// Default size=56 matches the primary full-screen lockup.
class ZibaLogo extends StatelessWidget {
  final ZibaLogoVariant variant;
  final double size;

  const ZibaLogo({
    super.key,
    this.variant = ZibaLogoVariant.dark,
    this.size = 56,
  });

  static const _lapis     = Color(0xFF6B8EC4);
  static const _lapisDark = Color(0xFF2C4A7C);
  static const _bgDark    = Color(0xFF0A0A0F);
  static const _bgLight   = Color(0xFFF5F0E8);
  static const _white     = Color(0xFFFFFFFF);
  static const _ink       = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final isDark     = variant != ZibaLogoVariant.light;
    final isMarkOnly = variant == ZibaLogoVariant.markOnly;

    final bg           = isDark ? _bgDark  : _bgLight;
    final markColor    = isDark ? _lapis   : _lapisDark;
    final fieldColor   = isDark ? _lapis   : _lapisDark;
    final fieldOpacity = isDark ? 0.12     : 0.08;
    final wordColor    = isDark ? _white   : _ink;

    final dividerH  = size * 0.93;
    final gap       = size * 0.43;
    final wordSize  = size * 0.36;
    final letterSp  = size * 0.18;
    final padding   = size * 0.86;

    return ClipRect(
      child: Container(
        color: bg,
        child: CustomPaint(
          painter: GirihPainter(color: fieldColor, opacity: fieldOpacity),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ز mark — use .SF Arabic to match the app icon glyph
                Text(
                  'ز',
                  style: TextStyle(
                    fontFamily: '.SF Arabic',
                    fontSize: size,
                    fontWeight: FontWeight.w300,
                    color: markColor,
                    shadows: [
                      Shadow(
                        color: markColor.withValues(alpha: 0.4),
                        blurRadius: size * 0.71,
                      ),
                    ],
                  ),
                ),
                if (!isMarkOnly) ...[
                  SizedBox(width: gap),
                  // Divider
                  Container(
                    width: 1,
                    height: dividerH,
                    color: _white.withValues(alpha: 0.15),
                  ),
                  SizedBox(width: gap),
                  // ZIBA wordmark
                  Text(
                    'ZIBA',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: wordSize,
                      fontWeight: FontWeight.w300,
                      color: wordColor,
                      letterSpacing: letterSp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
