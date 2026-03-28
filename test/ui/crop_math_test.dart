import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/ui/crop_math.dart';

void main() {
  test('wide image: cropWidth = height * screenAspect', () {
    // Screen 540×680 → aspect = 540/680 ≈ 0.7941
    // Image 3000×1000 native
    // cropWidth = 1000 * (540/680) ≈ 794.12
    final rect = calculateCropRect(
      imageNativeSize: const Size(3000, 1000),
      screenSize: const Size(540, 680),
      panOffset: 0.0,
    );

    expect(rect.left, closeTo(0.0, 0.01));
    expect(rect.top, 0.0);
    expect(rect.width, closeTo(794.12, 0.5));
    expect(rect.height, 1000.0);
  });

  test('wide image: panOffset=1.0 moves box to right edge', () {
    final rect = calculateCropRect(
      imageNativeSize: const Size(3000, 1000),
      screenSize: const Size(540, 680),
      panOffset: 1.0,
    );

    // maxLeft = 3000 - 794.12 ≈ 2205.88
    expect(rect.left, closeTo(2205.88, 1.0));
    expect(rect.right, closeTo(3000.0, 1.0));
  });

  test('portrait image: crop box covers full width', () {
    // Image taller than screen aspect → cropWidth = imageWidth
    final rect = calculateCropRect(
      imageNativeSize: const Size(800, 1200),
      screenSize: const Size(540, 680),
      panOffset: 0.0,
    );

    expect(rect.left, 0.0);
    expect(rect.width, 800.0); // clamped to imageWidth
  });

  test('square image with wide screen: cropWidth capped at imageWidth', () {
    final rect = calculateCropRect(
      imageNativeSize: const Size(1000, 1000),
      screenSize: const Size(1920, 1080),
      panOffset: 0.5,
    );

    expect(rect.width, 1000.0); // never exceeds image width
    expect(rect.left, 0.0);     // no pan room
  });

  test('needsPanSlider: true when image wider than screen aspect', () {
    expect(
      needsPanSlider(
        imageNativeSize: const Size(3000, 1000),
        screenSize: const Size(540, 680),
      ),
      isTrue,
    );
  });

  test('needsPanSlider: false when image narrower than screen aspect', () {
    expect(
      needsPanSlider(
        imageNativeSize: const Size(800, 1200),
        screenSize: const Size(540, 680),
      ),
      isFalse,
    );
  });
}
