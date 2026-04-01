import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Abstract adapter for setting wallpapers across platforms.
///
/// Each platform has its own implementation because wallpaper APIs
/// are deeply OS-specific. The factory constructor auto-selects
/// the right one at runtime.
abstract class WallpaperAdapter {
  /// Set the desktop/home screen wallpaper from a local file path.
  Future<bool> setWallpaper(String imagePath);

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
  Future<bool> setWallpaper(String imagePath) async {
    // Pre-crop portrait images to screen aspect ratio (top-anchored)
    // to prevent macOS from center-cropping off the top of tall paintings.
    final wallpaperPath = await _cropToScreenAspect(imagePath);

    // Method 1: osascript (works without entitlements)
    final result = await Process.run('osascript', [
      '-e',
      'tell application "System Events" to tell every desktop to set picture to POSIX file "$wallpaperPath"',
    ]);

    if (result.exitCode == 0) return true;

    // Method 2: sqlite3 direct (Sonoma+, if osascript fails)
    // This is a fallback for newer macOS versions
    final dbPath =
        '${Platform.environment['HOME']}/Library/Application Support/Dock/desktoppicture.db';
    final sqlResult = await Process.run('sqlite3', [
      dbPath,
      "UPDATE data SET value = '$wallpaperPath';",
    ]);

    if (sqlResult.exitCode == 0) {
      // Restart Dock to apply
      await Process.run('killall', ['Dock']);
      return true;
    }

    return false;
  }

  /// Crops a portrait image to the primary display's aspect ratio, anchored to top.
  ///
  /// Portrait images on landscape screens would otherwise be center-cropped by
  /// macOS, cutting off the top of the painting. We pre-crop to screen ratio
  /// anchored to top so the full upper composition is preserved.
  ///
  /// Returns the original path unchanged if no crop is needed (image is already
  /// wider than or equal to the screen aspect ratio) or if any step fails.
  Future<String> _cropToScreenAspect(String imagePath) async {
    try {
      // Get primary display aspect ratio
      final displays = ui.PlatformDispatcher.instance.displays;
      if (displays.isEmpty) return imagePath;
      final display = displays.first;
      final screenAspect = display.size.width / display.size.height;

      // Decode image to check dimensions
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      final imageWidth = srcImage.width;
      final imageHeight = srcImage.height;
      final imageAspect = imageWidth / imageHeight;

      // No vertical crop needed if image is already wider than screen ratio
      if (imageAspect >= screenAspect) {
        srcImage.dispose();
        return imagePath;
      }

      // Crop height for screen ratio, anchored to top of image
      final cropHeight =
          (imageWidth / screenAspect).round().clamp(1, imageHeight);

      // Render the top slice
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        srcImage,
        ui.Rect.fromLTWH(0, 0, imageWidth.toDouble(), cropHeight.toDouble()),
        ui.Rect.fromLTWH(0, 0, imageWidth.toDouble(), cropHeight.toDouble()),
        ui.Paint(),
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(imageWidth, cropHeight);
      srcImage.dispose();

      final byteData =
          await cropped.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      if (byteData == null) return imagePath;

      // Save alongside original (reuse path, overwrite each refresh)
      final croppedPath =
          imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_cropped.png');
      await File(croppedPath).writeAsBytes(byteData.buffer.asUint8List());

      return croppedPath;
    } catch (e) {
      debugPrint(
          '[MacOSWallpaperAdapter] Pre-crop failed, using original: $e');
      return imagePath;
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
  Future<bool> setWallpaper(String imagePath) async {
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
  Future<bool> setWallpaper(String imagePath) async {
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
// Android — Platform Channel to WallpaperManager
// ══════════════════════════════════════════════════

class AndroidWallpaperAdapter implements WallpaperAdapter {
  @override
  bool get isSupported => true;

  @override
  String get limitations => 'Sets home + lock screen wallpaper.';

  @override
  Future<bool> setWallpaper(String imagePath) async {
    // TODO: Implement via MethodChannel to native Kotlin code
    // See android/app/src/main/kotlin/.../WallpaperPlugin.kt
    //
    // final channel = MethodChannel('com.ziba/wallpaper');
    // final result = await channel.invokeMethod('setWallpaper', {
    //   'path': imagePath,
    //   'target': 'both', // 'home', 'lock', or 'both'
    // });
    // return result == true;

    throw UnimplementedError(
      'Android wallpaper requires platform channel setup. '
      'See ARCHITECTURE.md for Kotlin implementation.',
    );
  }
}

// ══════════════════════════════════════════════════
// iOS — Limited (no programmatic wallpaper API)
// ══════════════════════════════════════════════════

class IOSWallpaperAdapter implements WallpaperAdapter {
  @override
  bool get isSupported => false;

  @override
  String get limitations =>
      'iOS does not allow apps to set wallpaper programmatically. '
      'Ziba will show the artwork and offer a "Save to Photos" action.';

  @override
  Future<bool> setWallpaper(String imagePath) async {
    // iOS workaround: save image to photos library,
    // then prompt user to set it manually.
    // Could also use iOS 16+ Shortcuts integration.
    throw UnimplementedError(
      'iOS does not support programmatic wallpaper setting. '
      'Use the share sheet to save the image.',
    );
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
  Future<bool> setWallpaper(String imagePath) async => false;
}
