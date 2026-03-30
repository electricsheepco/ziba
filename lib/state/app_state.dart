import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wikiart_service.dart';
import '../data/database.dart';
import '../platform/wallpaper_adapter.dart';
import '../models/artwork.dart' as model;

// Active bottom-nav tab — allows any screen to switch tabs.
final activeTabProvider = StateProvider<int>((ref) => 0);

// ──────────────────────────────────────────────
// Singletons
// ──────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final wikiArtProvider = Provider<WikiArtService>((ref) => WikiArtService());

final wallpaperAdapterProvider =
    Provider<WallpaperAdapter>((ref) => WallpaperAdapter());

// ──────────────────────────────────────────────
// Current Artwork
// ──────────────────────────────────────────────

final currentArtworkProvider =
    AsyncNotifierProvider<CurrentArtworkNotifier, model.Artwork?>(
        CurrentArtworkNotifier.new);

class CurrentArtworkNotifier extends AsyncNotifier<model.Artwork?> {
  @override
  Future<model.Artwork?> build() async {
    // On startup, load the most recent from history
    // or fetch a new one
    return null;
  }

  /// Load an artwork directly from a DB row (e.g. tapped from History).
  void loadFromHistory(Artwork row) {
    state = AsyncData(model.Artwork(
      contentId: row.contentId,
      title: row.title,
      artistName: row.artistName,
      image: row.imageUrl,
      width: row.width,
      height: row.height,
      genre: row.genre,
      style: row.style,
    ));
  }

  /// Fetch a new random artwork and optionally set as wallpaper.
  Future<void> refresh({bool setWallpaper = true}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final wikiArt = ref.read(wikiArtProvider);
      final db = ref.read(databaseProvider);
      final adapter = ref.read(wallpaperAdapterProvider);

      // Exclude recent history
      final recentIds = await db.getRecentHistoryIds();

      // Detect if desktop → prefer landscape
      final isDesktop =
          Platform.isMacOS || Platform.isLinux || Platform.isWindows;

      // Fetch random artwork
      final artwork = await wikiArt.getRandomArtwork(
        preferLandscape: isDesktop,
        excludeIds: recentIds,
      );

      // Download image locally
      final localPath = await wikiArt.downloadImage(artwork);

      // Store in database
      await db.upsertArtwork(ArtworksCompanion.insert(
        contentId: Value(artwork.contentId),
        title: artwork.title,
        artistName: artwork.artistName,
        artistUrl: Value(artwork.artistUrl),
        completitionYear: Value(artwork.completitionYear),
        imageUrl: artwork.image,
        localPath: Value(localPath),
        width: Value(artwork.width),
        height: Value(artwork.height),
        genre: Value(artwork.genre),
        style: Value(artwork.style),
      ));

      // Add to history
      await db.addToHistory(artwork.contentId);

      // Set wallpaper
      if (setWallpaper && adapter.isSupported) {
        await adapter.setWallpaper(localPath);
      }

      return artwork.copyWith(setAt: DateTime.now());
    });
  }
}

// ──────────────────────────────────────────────
// History
// ──────────────────────────────────────────────

final historyProvider = StreamProvider<List<WallpaperHistoryWithArtwork>>(
    (ref) {
  final db = ref.watch(databaseProvider);
  return db.watchHistory();
});

// ──────────────────────────────────────────────
// Favorites
// ──────────────────────────────────────────────

final favoritesProvider = StreamProvider<List<Artwork>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFavorites();
});

final isFavoriteProvider =
    StreamProvider.family<bool, int>((ref, contentId) {
  final db = ref.watch(databaseProvider);
  return db.watchIsFavorite(contentId);
});

// ──────────────────────────────────────────────
// Settings
// ──────────────────────────────────────────────

class AppSettings {
  final Duration rotationInterval;
  final bool preferLandscape;
  final bool autoRotate;
  final Set<String> artMovementFilter; // empty = all
  final bool launchAtLogin;

  const AppSettings({
    this.rotationInterval = const Duration(hours: 24),
    this.preferLandscape = true,
    this.autoRotate = true,
    this.artMovementFilter = const {},
    this.launchAtLogin = false,
  });

  AppSettings copyWith({
    Duration? rotationInterval,
    bool? preferLandscape,
    bool? autoRotate,
    Set<String>? artMovementFilter,
    bool? launchAtLogin,
  }) =>
      AppSettings(
        rotationInterval: rotationInterval ?? this.rotationInterval,
        preferLandscape: preferLandscape ?? this.preferLandscape,
        autoRotate: autoRotate ?? this.autoRotate,
        artMovementFilter: artMovementFilter ?? this.artMovementFilter,
        launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      );
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kLaunchAtLogin = 'launch_at_login';

  @override
  AppSettings build() {
    // Load persisted launchAtLogin asynchronously and sync system state.
    _loadLaunchAtLogin();
    return const AppSettings();
  }

  Future<void> _loadLaunchAtLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_kLaunchAtLogin) ?? false;
    state = state.copyWith(launchAtLogin: value);
    // Sync system Login Items to match persisted preference.
    if (value) {
      await LaunchAtStartup.instance.enable();
    } else {
      await LaunchAtStartup.instance.disable();
    }
  }

  Future<void> setLaunchAtLogin(bool v) async {
    state = state.copyWith(launchAtLogin: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLaunchAtLogin, v);
    if (v) {
      await LaunchAtStartup.instance.enable();
    } else {
      await LaunchAtStartup.instance.disable();
    }
  }

  void setInterval(Duration d) =>
      state = state.copyWith(rotationInterval: d);
  void setPreferLandscape(bool v) =>
      state = state.copyWith(preferLandscape: v);
  void setAutoRotate(bool v) =>
      state = state.copyWith(autoRotate: v);
  void toggleArtMovement(String movement) {
    final current = Set<String>.from(state.artMovementFilter);
    if (current.contains(movement)) {
      current.remove(movement);
    } else {
      current.add(movement);
    }
    state = state.copyWith(artMovementFilter: current);
  }
}
