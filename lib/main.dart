import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:workmanager/workmanager.dart';
import 'data/database.dart';
import 'platform/wallpaper_adapter.dart';
import 'services/wikiart_service.dart';
import 'state/app_state.dart';
import 'ui/screens/home_screen.dart';

/// Background task dispatcher for WorkManager (Android only).
///
/// Runs in an isolate — no Riverpod, no Flutter engine. Uses raw instances.
/// WorkManager enforces a minimum period of 15 minutes regardless of the
/// in-app rotation interval.
@pragma('vm:entry-point')
void _workmanagerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != 'ziba.autorotate') return true;

    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    final wikiArt = WikiArtService();
    final adapter = WallpaperAdapter();

    try {
      final recentIds = await db.getRecentHistoryIds(limit: 30);
      final artwork = await wikiArt.getRandomArtwork(excludeIds: recentIds);

      await db.upsertArtwork(ArtworksCompanion(
        contentId: Value(artwork.contentId),
        title: Value(artwork.title),
        artistName: Value(artwork.artistName),
        artistUrl: Value(artwork.artistUrl),
        imageUrl: Value(artwork.image),
        width: artwork.width != null ? Value(artwork.width!) : const Value.absent(),
        height: artwork.height != null ? Value(artwork.height!) : const Value.absent(),
        genre: artwork.genre != null ? Value(artwork.genre!) : const Value.absent(),
        style: artwork.style != null ? Value(artwork.style!) : const Value.absent(),
      ));

      final localPath = await wikiArt.downloadImage(artwork);
      final success = await adapter.setWallpaper(localPath);
      if (success) await db.addToHistory(artwork.contentId);
    } catch (e) {
      debugPrint('[WorkManager] autorotate failed: $e');
      return false;
    } finally {
      await db.close();
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Workmanager().initialize(_workmanagerDispatcher);
  }

  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    LaunchAtStartup.instance.setup(
      appName: 'Ziba',
      appPath: Platform.resolvedExecutable,
    );
  }

  runApp(const ProviderScope(child: ZibaApp()));
}

class ZibaApp extends ConsumerWidget {
  const ZibaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Ziba',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      darkTheme: buildTheme(Brightness.dark),
      theme: buildTheme(Brightness.light),
      home: const HomeScreen(),
    );
  }

  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A2E),
        brightness: brightness,
        surface: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F0),
        onSurface: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F0),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
        bodyLarge: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontFeatures: const [FontFeature('smcp')],
          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF444444),
        ),
        bodyMedium: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontFeatures: const [FontFeature('smcp')],
          color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature('smcp')],
          color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
          fontFeatures: const [FontFeature('smcp')],
          color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F0),
        indicatorColor: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
