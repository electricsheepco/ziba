import 'dart:ui';

/// Calculates the source crop rectangle for wallpaper cropping.
///
/// Returns a [Rect] in the image's native pixel coordinate space.
///
/// [imageNativeSize] — native pixel dimensions of the source image.
/// [screenSize] — current screen dimensions (from MediaQuery).
/// [panOffset] — 0.0 = leftmost position, 1.0 = rightmost position.
Rect calculateCropRect({
  required Size imageNativeSize,
  required Size screenSize,
  required double panOffset,
}) {
  final screenAspect = screenSize.width / screenSize.height;
  final cropWidth =
      (imageNativeSize.height * screenAspect).clamp(0.0, imageNativeSize.width);
  final maxLeft = imageNativeSize.width - cropWidth;
  final left = maxLeft * panOffset;

  return Rect.fromLTWH(left, 0, cropWidth, imageNativeSize.height);
}

/// Returns true if the pan slider should be shown.
///
/// Only shown when the image is wider than the screen aspect ratio.
bool needsPanSlider({
  required Size imageNativeSize,
  required Size screenSize,
}) {
  if (imageNativeSize.height == 0) return false;
  final imageAspect = imageNativeSize.width / imageNativeSize.height;
  final screenAspect = screenSize.width / screenSize.height;
  return imageAspect > screenAspect;
}
