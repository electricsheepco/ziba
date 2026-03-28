import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/ui/widgets/girih_painter.dart';

void main() {
  test('GirihPainter shouldRepaint returns false for same instance', () {
    final p = GirihPainter(color: const Color(0xFF6B8EC4), opacity: 0.12);
    expect(p.shouldRepaint(p), isFalse);
  });

  test('GirihPainter shouldRepaint returns true when color changes', () {
    final a = GirihPainter(color: const Color(0xFF6B8EC4), opacity: 0.12);
    final b = GirihPainter(color: const Color(0xFF2C4A7C), opacity: 0.12);
    expect(a.shouldRepaint(b), isTrue);
  });

  testWidgets('GirihPainter renders inside CustomPaint without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 100,
          child: CustomPaint(
            painter: GirihPainter(
              color: const Color(0xFF6B8EC4),
              opacity: 0.12,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
