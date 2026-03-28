import 'dart:io';
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
    // Method 1: osascript (works without entitlements)
    final result = await Process.run('osascript', [
      '-e',
      'tell application "System Events" to tell every desktop to set picture to POSIX file "$imagePath"',
    ]);

    if (result.exitCode == 0) return true;

    // Method 2: sqlite3 direct (Sonoma+, if osascript fails)
    // This is a fallback for newer macOS versions
    final dbPath =
        '${Platform.environment['HOME']}/Library/Application Support/Dock/desktoppicture.db';
    final sqlResult = await Process.run('sqlite3', [
      dbPath,
      "UPDATE data SET value = '$imagePath';",
    ]);

    if (sqlResult.exitCode == 0) {
      // Restart Dock to apply
      await Process.run('killall', ['Dock']);
      return true;
    }

    return false;
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
