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

      // Fetch random artwork (list index — no style/genre/technique)
      final artwork = await wikiArt.getRandomArtwork(
        preferLandscape: isDesktop,
        excludeIds: recentIds,
      );

      // Enrich with detail endpoint (style, genre, technique, galleryName only).
      // The detail endpoint scrambles artistName order — keep list data for
      // everything except the metadata fields that only the detail provides.
      final detail = await wikiArt
          .getPaintingDetail(artwork.contentId)
          .catchError((_) => null);
      final enriched = detail == null
          ? artwork
          : artwork.copyWith(
              style: detail.style,
              genre: detail.genre,
              technique: detail.technique,
              galleryName: detail.galleryName,
            );

      // Download image locally
      final localPath = await wikiArt.downloadImage(artwork);

      // Store in database
      await db.upsertArtwork(ArtworksCompanion.insert(
        contentId: Value(enriched.contentId),
        title: enriched.title,
        artistName: enriched.artistName,
        artistUrl: Value(enriched.artistUrl),
        completitionYear: Value(enriched.completitionYear),
        imageUrl: enriched.image,
        localPath: Value(localPath),
        width: Value(enriched.width),
        height: Value(enriched.height),
        genre: Value(enriched.genre),
        style: Value(enriched.style),
      ));

      // Add to history
      await db.addToHistory(artwork.contentId);

      // Set wallpaper
      if (setWallpaper && adapter.isSupported) {
        await adapter.setWallpaper(localPath);
      }

      return enriched.copyWith(setAt: DateTime.now());
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
  static const _kAutoRotate = 'auto_rotate';
  static const _kRotationIntervalMs = 'rotation_interval_ms';
  static const _kPreferLandscape = 'prefer_landscape';
  static const _kArtMovements = 'art_movement_filter';

  @override
  AppSettings build() {
    // Load all persisted settings asynchronously on startup.
    _loadAllSettings();
    return const AppSettings();
  }

  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final autoRotate = prefs.getBool(_kAutoRotate) ?? true;
    final intervalMs = prefs.getInt(_kRotationIntervalMs) ??
        const Duration(hours: 24).inMilliseconds;
    final preferLandscape = prefs.getBool(_kPreferLandscape) ?? true;
    final movementsList = prefs.getStringList(_kArtMovements) ?? [];
    final launchAtLogin = prefs.getBool(_kLaunchAtLogin) ?? false;

    state = state.copyWith(
      autoRotate: autoRotate,
      rotationInterval: Duration(milliseconds: intervalMs),
      preferLandscape: preferLandscape,
      artMovementFilter: Set<String>.from(movementsList),
      launchAtLogin: launchAtLogin,
    );

    // Sync system Login Items to match persisted preference.
    if (launchAtLogin) {
      await LaunchAtStartup.instance.enable();
    } else {
      await LaunchAtStartup.instance.disable();
    }
  }

  Future<void> setAutoRotate(bool v) async {
    state = state.copyWith(autoRotate: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoRotate, v);
  }

  Future<void> setInterval(Duration d) async {
    state = state.copyWith(rotationInterval: d);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRotationIntervalMs, d.inMilliseconds);
  }

  Future<void> setPreferLandscape(bool v) async {
    state = state.copyWith(preferLandscape: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPreferLandscape, v);
  }

  Future<void> toggleArtMovement(String movement) async {
    final current = Set<String>.from(state.artMovementFilter);
    if (current.contains(movement)) {
      current.remove(movement);
    } else {
      current.add(movement);
    }
    state = state.copyWith(artMovementFilter: current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kArtMovements, current.toList());
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
}
