import 'package:flutter/material.dart';

/// Tiles a simplified Girih star tessellation across the canvas.
///
/// The tile unit is an 80×80 logical-pixel cell containing a 10-pointed
/// star polygon (Girih-style) plus three construction lines.
class GirihPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const GirihPainter({required this.color, required this.opacity});

  // 10-pointed star polygon normalised to an 80×80 tile.
  // SVG reference: polygon points="40,4 49,30 75,30 55,47 62,73 40,58 18,73 25,47 5,30 31,30"
  static const List<Offset> _starPoints = [
    Offset(40, 4),  Offset(49, 30), Offset(75, 30),
    Offset(55, 47), Offset(62, 73), Offset(40, 58),
    Offset(18, 73), Offset(25, 47), Offset(5,  30),
    Offset(31, 30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const tileSize = 80.0;
    final cols = (size.width  / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final dx = col * tileSize;
        final dy = row * tileSize;

        final path = Path();
        for (var i = 0; i < _starPoints.length; i++) {
          final p = _starPoints[i];
          if (i == 0) {
            path.moveTo(dx + p.dx, dy + p.dy);
          } else {
            path.lineTo(dx + p.dx, dy + p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);

        canvas.drawLine(
          Offset(dx + 40, dy + 4),
          Offset(dx + 40, dy + 58),
          paint,
        );
        canvas.drawLine(
          Offset(dx + 5,  dy + 30),
          Offset(dx + 75, dy + 30),
          paint,
        );
        canvas.drawLine(
          Offset(dx + 18, dy + 73),
          Offset(dx + 62, dy + 73),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GirihPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
