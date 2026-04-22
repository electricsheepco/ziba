import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

/// Abstract adapter for setting wallpapers across platforms.
///
/// Each platform has its own implementation because wallpaper APIs
/// are deeply OS-specific. The factory constructor auto-selects
/// the right one at runtime.
abstract class WallpaperAdapter {
  /// Set the desktop/home screen wallpaper from a local file path.
  ///
  /// When [bypassDisplayCrop] is true (manual user crop), the image is
  /// already cropped for the primary display and should be set as-is on all
  /// displays without further per-display processing.
  Future<bool> setWallpaper(String imagePath, {bool bypassDisplayCrop = false});

  /// Check if wallpaper setting is supported on this platform.
  bool get isSupported;

  /// Human-readable description of any limitations.
  String get limitations;

  /// Factory: returns the correct adapter for the current platform.
  factory WallpaperAdapter() {
    if (kIsWeb) return _UnsupportedAdapter('Web');
    if (Platform.isMacOS) return MacOSWallpaperAdapter();
    if (Platform.isLinux) return LinuxWallpaperAdapter();
    if (Platform.isWindows) return WindowsWallpaperAdapter();
    if (Platform.isAndroid) return AndroidWallpaperAdapter();
    if (Platform.isIOS) return IOSWallpaperAdapter();
    return _UnsupportedAdapter('Unknown');
  }
}

// ══════════════════════════════════════════════════
// macOS — osascript + NSWorkspace via process
// ══════════════════════════════════════════════════

class MacOSWallpaperAdapter implements WallpaperAdapter {
  @override
  bool get isSupported => true;

  @override
  String get limitations => 'Sets wallpaper on all desktops/spaces.';

  @override
  Future<bool> setWallpaper(String imagePath,
      {bool bypassDisplayCrop = false}) async {
    final displays = ui.PlatformDispatcher.instance.displays;

    // When called from manual user crop the image is already correctly cropped
    // for the primary display — set it on all desktops without re-cropping.
    if (bypassDisplayCrop) {
      final count = displays.isEmpty ? 1 : displays.length;
      final scriptLines = ['tell application "System Events"'];
      for (int i = 0; i < count; i++) {
        scriptLines
          ..add('  try')
          ..add('    tell desktop ${i + 1}')
          ..add('      set picture to POSIX file "$imagePath"')
          ..add('      set picture scale to 1')
          ..add('    end tell')
          ..add('  end try');
      }
      scriptLines.add('end tell');
      final result =
          await Process.run('osascript', ['-e', scriptLines.join('\n')]);
      return result.exitCode == 0;
    }

    // Generate a per-display crop. Different screens have different aspect ratios
    // (e.g. built-in 16:10 vs LG ultrawide 21:9) and each needs its own crop.
    final displayList = displays.toList();
    final results = <({String path, bool cropped})>[];
    for (int i = 0; i < displayList.length; i++) {
      results.add(
          await _cropForDisplay(imagePath, displayList[i], displayIndex: i));
    }
    if (results.isEmpty) results.add((path: imagePath, cropped: false));

    // Method 1: osascript — target each desktop by index.
    // desktop N in System Events matches display N-1 in macOS display order,
    // which should align with Flutter's displays list (main display first).
    // Each desktop gets its own pre-cropped image.
    //
    // picture scale values: 1=fill (zoom to fill, no bars), 2=fit (show full, may bar).
    // When we pre-cropped to the display ratio, fill is lossless.
    // When the image already matches the display, fit preserves the full painting.
    final scriptLines = ['tell application "System Events"'];
    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      final scale = r.cropped ? 1 : 2;
      scriptLines
        ..add('  try')
        ..add('    tell desktop ${i + 1}')
        ..add('      set picture to POSIX file "${r.path}"')
        ..add('      set picture scale to $scale')
        ..add('    end tell')
        ..add('  end try');
    }
    scriptLines.add('end tell');

    final result =
        await Process.run('osascript', ['-e', scriptLines.join('\n')]);
    if (result.exitCode == 0) return true;

    // Method 2: sqlite3 direct (Sonoma+, if osascript fails). Sets all desktops
    // to the first crop (main display). Not per-display but better than nothing.
    final dbPath =
        '${Platform.environment['HOME']}/Library/Application Support/Dock/desktoppicture.db';
    final sqlResult = await Process.run('sqlite3', [
      dbPath,
      "UPDATE data SET value = '${results.first.path}';",
    ]);

    if (sqlResult.exitCode == 0) {
      await Process.run('killall', ['Dock']);
      return true;
    }

    return false;
  }

  /// Crops [imagePath] to [display]'s exact aspect ratio and saves it with a
  /// display-indexed suffix so each screen gets its own correctly-proportioned file.
  ///
  /// - Image taller than display ratio: top-anchor crop (preserves upper composition).
  /// - Image wider than display ratio: center-crop horizontally (even side trim).
  /// - Image already within 5% of display ratio: returned unchanged (cropped=false).
  ///
  /// Returns the original path with cropped=false if any step fails.
  Future<({String path, bool cropped})> _cropForDisplay(
    String imagePath,
    ui.Display display, {
    required int displayIndex,
  }) async {
    try {
      final screenW = display.size.width;
      final screenH = display.size.height;
      if (screenW == 0 || screenH == 0) {
        debugPrint(
            '[MacOSWallpaperAdapter] Display $displayIndex reported size 0 — skipping crop');
        return (path: imagePath, cropped: false);
      }
      final screenAspect = screenW / screenH;

      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      final imageWidth = srcImage.width;
      final imageHeight = srcImage.height;
      final imageAspect = imageWidth / imageHeight;

      debugPrint(
          '[MacOSWallpaperAdapter] Display $displayIndex '
          '(${screenW.toInt()}×${screenH.toInt()}, ratio=${screenAspect.toStringAsFixed(3)}): '
          'image $imageWidth×$imageHeight ratio=${imageAspect.toStringAsFixed(3)}');

      // Within 5% of display aspect — no crop needed; use fit-to-screen instead.
      if ((imageAspect - screenAspect).abs() / screenAspect < 0.05) {
        srcImage.dispose();
        debugPrint(
            '[MacOSWallpaperAdapter] Display $displayIndex: ratio match within 5%, no crop');
        return (path: imagePath, cropped: false);
      }

      final int srcX, srcY, srcW, srcH;
      if (imageAspect > screenAspect) {
        // Wider than display — trim sides equally, keep full height.
        srcH = imageHeight;
        srcW = (imageHeight * screenAspect).round().clamp(1, imageWidth);
        srcX = (imageWidth - srcW) ~/ 2;
        srcY = 0;
      } else {
        // Taller than display — trim bottom, keep top (composition anchor).
        srcW = imageWidth;
        srcH = (imageWidth / screenAspect).round().clamp(1, imageHeight);
        srcX = 0;
        srcY = 0;
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        srcImage,
        ui.Rect.fromLTWH(
            srcX.toDouble(), srcY.toDouble(), srcW.toDouble(), srcH.toDouble()),
        ui.Rect.fromLTWH(0, 0, srcW.toDouble(), srcH.toDouble()),
        ui.Paint(),
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(srcW, srcH);
      srcImage.dispose();

      final byteData =
          await cropped.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      if (byteData == null) return (path: imagePath, cropped: false);

      final croppedPath = imagePath.replaceAll(
          RegExp(r'\.[^.]+$'), '_cropped_$displayIndex.png');
      await File(croppedPath).writeAsBytes(byteData.buffer.asUint8List());

      debugPrint(
          '[MacOSWallpaperAdapter] Display $displayIndex: '
          'cropped $imageWidth×$imageHeight → $srcW×$srcH');

      return (path: croppedPath, cropped: true);
    } catch (e) {
      debugPrint(
          '[MacOSWallpaperAdapter] Pre-crop failed for display $displayIndex: $e');
      return (path: imagePath, cropped: false);
    }
  }
}

// ══════════════════════════════════════════════════
// Linux — auto-detect DE, use appropriate command
// ══════════════════════════════════════════════════

class LinuxWallpaperAdapter implements WallpaperAdapter {
  @override
  bool get isSupported => true;

  @override
  String get limitations =>
      'Supports GNOME, KDE Plasma, XFCE, Hyprland, sway, i3/feh.';

  @override
  Future<bool> setWallpaper(String imagePath,
      {bool bypassDisplayCrop = false}) async {
    final de = _detectDesktopEnvironment();

    switch (de) {
      case _LinuxDE.gnome:
      case _LinuxDE.cinnamon:
      case _LinuxDE.unity:
        return _setGnome(imagePath);
      case _LinuxDE.kde:
        return _setKDE(imagePath);
      case _LinuxDE.xfce:
        return _setXFCE(imagePath);
      case _LinuxDE.sway:
      case _LinuxDE.hyprland:
        return _setSway(imagePath);
      case _LinuxDE.unknown:
        // Fallback: try feh (works on most X11 setups)
        return _setFeh(imagePath);
    }
  }

  _LinuxDE _detectDesktopEnvironment() {
    final xdgDesktop =
        (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '').toLowerCase();
    final desktopSession =
        (Platform.environment['DESKTOP_SESSION'] ?? '').toLowerCase();
    final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];

    if (xdgDesktop.contains('gnome') || desktopSession.contains('gnome')) {
      return _LinuxDE.gnome;
    }
    if (xdgDesktop.contains('kde') || desktopSession.contains('plasma')) {
      return _LinuxDE.kde;
    }
    if (xdgDesktop.contains('xfce')) return _LinuxDE.xfce;
    if (xdgDesktop.contains('cinnamon')) return _LinuxDE.cinnamon;
    if (xdgDesktop.contains('unity')) return _LinuxDE.unity;
    if (xdgDesktop.contains('sway')) return _LinuxDE.sway;
    if (xdgDesktop.contains('hyprland')) return _LinuxDE.hyprland;
    if (waylandDisplay != null && xdgDesktop.contains('sway')) {
      return _LinuxDE.sway;
    }

    return _LinuxDE.unknown;
  }

  Future<bool> _setGnome(String path) async {
    final uri = 'file://$path';
    final r1 = await Process.run('gsettings', [
      'set',
      'org.gnome.desktop.background',
      'picture-uri',
      uri,
    ]);
    // Also set dark variant
    await Process.run('gsettings', [
      'set',
      'org.gnome.desktop.background',
      'picture-uri-dark',
      uri,
    ]);
    return r1.exitCode == 0;
  }

  Future<bool> _setKDE(String path) async {
    final result =
        await Process.run('plasma-apply-wallpaperimage', [path]);
    return result.exitCode == 0;
  }

  Future<bool> _setXFCE(String path) async {
    // XFCE uses xfconf-query, need to set for each monitor
    final result = await Process.run('xfconf-query', [
      '-c',
      'xfce4-desktop',
      '-p',
      '/backdrop/screen0/monitor0/workspace0/last-image',
      '-s',
      path,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> _setSway(String path) async {
    final result = await Process.run('swaybg', ['-i', path, '-m', 'fill']);
    return result.exitCode == 0;
  }

  Future<bool> _setFeh(String path) async {
    final result = await Process.run('feh', ['--bg-fill', path]);
    return result.exitCode == 0;
  }
}

enum _LinuxDE { gnome, kde, xfce, cinnamon, unity, sway, hyprland, unknown }

// ══════════════════════════════════════════════════
// Windows — PowerShell SystemParametersInfo
// ══════════════════════════════════════════════════

class WindowsWallpaperAdapter implements WallpaperAdapter {
  @override
  bool get isSupported => true;

  @override
  String get limitations => 'Sets desktop wallpaper via Win32 API.';

  @override
  Future<bool> setWallpaper(String imagePath,
      {bool bypassDisplayCrop = false}) async {
    // Convert forward slashes for Windows
    final winPath = imagePath.replaceAll('/', '\\');

    final script = '''
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo(0x0014, 0, "$winPath", 0x01 -bor 0x02)
''';

    final result = await Process.run(
      'powershell',
      ['-Command', script],
      runInShell: true,
    );
    return result.exitCode == 0;
  }
}

// ══════════════════════════════════════════════════
// Android — WallpaperManager via MethodChannel
// ══════════════════════════════════════════════════

class AndroidWallpaperAdapter implements WallpaperAdapter {
  static const _channel = MethodChannel('com.ziba/wallpaper');

  @override
  bool get isSupported => true;

  @override
  String get limitations => 'Sets home + lock screen wallpaper via WallpaperManager.';

  @override
  Future<bool> setWallpaper(String imagePath,
      {bool bypassDisplayCrop = false}) async {
    try {
      final result = await _channel.invokeMethod<bool>('setWallpaper', {
        'path': imagePath,
        'target': 'both',
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('[AndroidWallpaperAdapter] setWallpaper failed: ${e.message}');
      return false;
    }
  }
}

// ══════════════════════════════════════════════════
// iOS — Save to Photos Library (no programmatic API)
// ══════════════════════════════════════════════════

class IOSWallpaperAdapter implements WallpaperAdapter {
  @override
  // isSupported = true: we save to Photos even if we can't set directly.
  // Caller should check limitations to render iOS-specific UI.
  bool get isSupported => true;

  @override
  String get limitations =>
      'iOS does not allow apps to set wallpaper programmatically. '
      'Ziba saves the artwork to your Photos library — set it as wallpaper from Settings.';

  @override
  Future<bool> setWallpaper(String imagePath,
      {bool bypassDisplayCrop = false}) async {
    try {
      await Gal.putImage(imagePath, album: 'Ziba');
      return true;
    } catch (e) {
      debugPrint('[IOSWallpaperAdapter] Failed to save to Photos: $e');
      return false;
    }
  }
}

// ══════════════════════════════════════════════════
// Unsupported fallback
// ══════════════════════════════════════════════════

class _UnsupportedAdapter implements WallpaperAdapter {
  final String platform;
  _UnsupportedAdapter(this.platform);

  @override
  bool get isSupported => false;

  @override
  String get limitations => '$platform is not supported for wallpaper setting.';

  @override
  Future<bool> setWallpaper(String imagePath,
      {bool bypassDisplayCrop = false}) async => false;
}
