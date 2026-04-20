import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
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
    // On startup, load the most recent artwork from history (no network call).
    // Returns null on first launch — shows the empty state with a prompt.
    final db = ref.read(databaseProvider);
    final entry = await db.getLatestHistoryEntry();
    if (entry == null) return null;
    final row = entry.artwork;
    return model.Artwork(
      contentId: row.contentId,
      title: row.title,
      artistName: row.artistName,
      artistUrl: row.artistUrl,
      image: row.imageUrl,
      width: row.width,
      height: row.height,
      genre: row.genre,
      style: row.style,
      setAt: entry.history.setAt,
    );
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

  /// Fetch one artwork, enrich with detail data, and check movement filter.
  /// Returns null if the filter is active and the artwork's style doesn't match.
  Future<model.Artwork?> _fetchEnriched({
    required WikiArtService wikiArt,
    required AppDatabase db,
    required bool preferLandscape,
    required Set<String> movementFilter,
    required List<int> recentIds,
  }) async {
    final artwork = await wikiArt.getRandomArtwork(
      preferLandscape: preferLandscape,
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

    // If filter active: style-null artworks can't be matched — signal retry.
    // Only let the artwork through if style is known and matches the filter.
    if (movementFilter.isNotEmpty) {
      if (enriched.style == null) return null; // style unknown — retry
      final styleLC = enriched.style!.toLowerCase();
      final matches =
          movementFilter.any((m) => styleLC.contains(m.toLowerCase()));
      if (!matches) return null;
    }

    return enriched;
  }

  /// Fetch a new random artwork and optionally set as wallpaper.
  Future<void> refresh({bool setWallpaper = true}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final wikiArt = ref.read(wikiArtProvider);
      final db = ref.read(databaseProvider);
      final adapter = ref.read(wallpaperAdapterProvider);
      final settings = ref.read(settingsProvider);

      // Fetch once so all retry attempts share the same exclusion list.
      final recentIds = await db.getRecentHistoryIds();

      // Try up to 5 times to find an artwork matching the movement filter.
      model.Artwork? enriched;
      for (int i = 0; i < 5; i++) {
        enriched = await _fetchEnriched(
          wikiArt: wikiArt,
          db: db,
          preferLandscape: settings.preferLandscape,
          movementFilter: settings.artMovementFilter,
          recentIds: recentIds,
        );
        if (enriched != null) break;
      }

      // Final fallback: one unconditional fetch ignoring the filter.
      // movementFilter: const {} means no filter — always returns something.
      enriched ??= await _fetchEnriched(
        wikiArt: wikiArt,
        db: db,
        preferLandscape: settings.preferLandscape,
        movementFilter: const {}, // no filter — always returns something
        recentIds: recentIds,
      );

      // Guard: if WikiArt is unreachable even on the filter-free fallback
      // (e.g. getArtistList() returned empty due to network failure),
      // fail loudly rather than crashing on a null dereference below.
      if (enriched == null) {
        throw Exception('Failed to fetch artwork — WikiArt may be unreachable');
      }

      // Download image locally
      final localPath = await wikiArt.downloadImage(enriched);

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

      await db.addToHistory(enriched.contentId);

      if (setWallpaper && adapter.isSupported) {
        await adapter.setWallpaper(localPath);
      }

      return enriched.copyWith(setAt: DateTime.now());
    });

    if (state is AsyncError) {
      final err = state as AsyncError;
      debugPrint('[refresh] Failed: ${err.error}\n${err.stackTrace}');
    }
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
  final ThemeMode themeMode;

  const AppSettings({
    this.rotationInterval = const Duration(hours: 24),
    this.preferLandscape = true,
    this.autoRotate = true,
    this.artMovementFilter = const {},
    this.launchAtLogin = false,
    this.themeMode = ThemeMode.dark,
  });

  AppSettings copyWith({
    Duration? rotationInterval,
    bool? preferLandscape,
    bool? autoRotate,
    Set<String>? artMovementFilter,
    bool? launchAtLogin,
    ThemeMode? themeMode,
  }) =>
      AppSettings(
        rotationInterval: rotationInterval ?? this.rotationInterval,
        preferLandscape: preferLandscape ?? this.preferLandscape,
        autoRotate: autoRotate ?? this.autoRotate,
        artMovementFilter: artMovementFilter ?? this.artMovementFilter,
        launchAtLogin: launchAtLogin ?? this.launchAtLogin,
        themeMode: themeMode ?? this.themeMode,
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
  static const _kThemeMode = 'theme_mode';

  @override
  AppSettings build() {
    // Load all persisted settings asynchronously on startup.
    _loadAllSettings();
    return const AppSettings();
  }

  Future<void> _loadAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final autoRotate = prefs.getBool(_kAutoRotate) ?? true;
      final intervalMs = prefs.getInt(_kRotationIntervalMs) ??
          const Duration(hours: 24).inMilliseconds;
      final preferLandscape = prefs.getBool(_kPreferLandscape) ?? true;
      final movementsList = prefs.getStringList(_kArtMovements) ?? [];
      final launchAtLogin = prefs.getBool(_kLaunchAtLogin) ?? false;
      final themeModeStr = prefs.getString(_kThemeMode) ?? 'dark';
      final themeMode = _themeModeFromString(themeModeStr);

      state = state.copyWith(
        autoRotate: autoRotate,
        rotationInterval: Duration(milliseconds: intervalMs),
        preferLandscape: preferLandscape,
        artMovementFilter: Set<String>.from(movementsList),
        launchAtLogin: launchAtLogin,
        themeMode: themeMode,
      );

      // Sync system Login Items to match persisted preference.
      // Wrapped separately: LaunchAtStartup plugin is unavailable in flutter run.
      try {
        if (launchAtLogin) {
          await LaunchAtStartup.instance.enable();
        } else {
          await LaunchAtStartup.instance.disable();
        }
      } catch (e) {
        debugPrint('[SettingsNotifier] LaunchAtStartup sync skipped: $e');
      }
    } catch (e, stack) {
      debugPrint('[SettingsNotifier] Failed to load settings: $e\n$stack');
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

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, _themeModeToString(mode));
  }
}

ThemeMode _themeModeFromString(String s) => switch (s) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

String _themeModeToString(ThemeMode m) => switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };

// ──────────────────────────────────────────────
// Auto-rotation timer
// ──────────────────────────────────────────────

/// Manages the auto-rotation timer. Must be watched in a long-lived widget.
///
/// Uses artwork.setAt (persisted in history DB) to calculate the remaining
/// time until the next rotation — so the interval survives app restarts.
/// The provider rebuilds whenever the artwork changes (after each refresh),
/// resetting the timer to the full interval from the new setAt.
final autoRotateTimerProvider = Provider<void>((ref) {
  final autoRotate = ref.watch(settingsProvider.select((s) => s.autoRotate));
  final interval = ref.watch(settingsProvider.select((s) => s.rotationInterval));

  if (!autoRotate) return;

  // Don't schedule while the provider is still loading the initial artwork.
  final artworkAsync = ref.watch(currentArtworkProvider);
  if (artworkAsync.isLoading) return;

  // No artwork yet (first launch) — let the user trigger the first one manually.
  final artwork = artworkAsync.valueOrNull;
  if (artwork == null) return;

  // Calculate how long until the next rotation is due.
  final setAt = artwork.setAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final elapsed = DateTime.now().difference(setAt);
  final remaining = interval - elapsed;
  final delay = remaining > Duration.zero ? remaining : Duration.zero;

  final timer = Timer(delay, () {
    if (!ref.read(currentArtworkProvider).isLoading) {
      ref.read(currentArtworkProvider.notifier).refresh();
    }
  });

  ref.onDispose(timer.cancel);
});
