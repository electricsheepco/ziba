import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/artwork.dart';

/// WikiArt JSON API client.
///
/// Endpoints don't require auth for basic read access.
/// For heavy usage, register at wikiart.org/en/App/GetApi
/// and pass accessCode + secretCode to authenticate.
class WikiArtService {
  static const _baseUrl = 'https://www.wikiart.org/en/App';

  final Dio _dio;
  final Random _random = Random();

  // Local cache of artwork index for fast random picks
  List<Artwork>? _cachedIndex;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(hours: 24);

  // Artist list cache (7-day TTL on disk, 24h in-memory)
  List<ArtistSummary>? _cachedArtists;
  DateTime? _artistsCacheTimestamp;
  static const _artistsCacheDuration = Duration(hours: 24);

  // Recency exclusion: last 10 artist URLs shown in this session (used in Task 5)
  final List<String> _recentArtistUrls = [];
  static const _recentArtistLimit = 10;

  WikiArtService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'User-Agent': 'Ziba/1.0 (Flutter; Art Wallpaper App)',
              },
            ));

  // ──────────────────────────────────────────────
  // Auth (optional, for higher rate limits)
  // ──────────────────────────────────────────────

  String? _sessionKey;

  Future<void> authenticate({
    required String accessCode,
    required String secretCode,
  }) async {
    final response = await _dio.get(
      '/User/Login',
      queryParameters: {
        'accessCode': accessCode,
        'secretCode': secretCode,
      },
    );
    if (response.data is Map && response.data['SessionKey'] != null) {
      _sessionKey = response.data['SessionKey'];
    }
  }

  Map<String, dynamic> _authParams([Map<String, dynamic>? extra]) {
    final params = <String, dynamic>{};
    if (_sessionKey != null) {
      params['authSessionKey'] = _sessionKey;
    }
    if (extra != null) params.addAll(extra);
    return params;
  }

  // ──────────────────────────────────────────────
  // Core API Methods
  // ──────────────────────────────────────────────

  /// Fetch most viewed paintings (curated, good quality).
  /// Returns up to ~60 paintings per call.
  Future<List<Artwork>> getMostViewedPaintings() async {
    final response = await _dio.get(
      '/Painting/MostViewedPaintings',
      queryParameters: _authParams(),
    );
    return _parsePaintingList(response.data);
  }

  /// Fetch all artists alphabetically (paginated).
  Future<List<ArtistSummary>> getArtists({String? paginationToken}) async {
    final response = await _dio.get(
      '/Artist/AlphabetJson',
      queryParameters: _authParams({
        'v': 'new',
        if (paginationToken != null) 'paginationToken': paginationToken,
      }),
    );
    if (response.data is List) {
      return (response.data as List)
          .map((e) => ArtistSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Returns all WikiArt artists.
  /// Served from in-memory cache (24h), falling back to disk cache (7-day TTL),
  /// then the WikiArt AlphabetJson API.
  Future<List<ArtistSummary>> getArtistList() async {
    // In-memory cache (24h)
    if (_cachedArtists != null &&
        _artistsCacheTimestamp != null &&
        DateTime.now().difference(_artistsCacheTimestamp!) <
            _artistsCacheDuration) {
      return _cachedArtists!;
    }

    // Disk cache (7 days)
    final diskCache = await _loadArtistDiskCache();
    if (diskCache != null) {
      _cachedArtists = diskCache;
      _artistsCacheTimestamp = DateTime.now();
      return _cachedArtists!;
    }

    // Fetch from API — AlphabetJson returns all artists in one response
    final artists = await getArtists();
    if (artists.isNotEmpty) {
      _cachedArtists = artists;
      _artistsCacheTimestamp = DateTime.now();
      await _saveArtistDiskCache(artists);
    }

    return _cachedArtists ?? [];
  }

  /// Fetch paintings by a specific artist.
  Future<List<Artwork>> getPaintingsByArtist(String artistUrl) async {
    final response = await _dio.get(
      '/Painting/PaintingsByArtist',
      queryParameters: _authParams({
        'artistUrl': artistUrl,
        'json': '2',
      }),
    );
    return _parsePaintingList(response.data);
  }

  /// Get a single painting's details.
  Future<Artwork?> getPaintingDetail(int contentId) async {
    final response = await _dio.get(
      '/Painting/ImageJson/$contentId',
      queryParameters: _authParams(),
    );
    if (response.data is Map) {
      return Artwork.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // Random Artwork Selection
  // ──────────────────────────────────────────────

  /// Get a random artwork suitable for wallpaper.
  ///
  /// Strategy (diversity):
  /// 1. Load artist list from cache (or fetch if stale)
  /// 2. Pick a random artist, excluding the last 10 shown (in-memory)
  /// 3. Fetch that artist's paintings, filter for ≥1920px on longest edge
  /// 4. Pick a random painting from the filtered list
  /// 5. Retry up to 5 times with a new artist if no usable paintings found
  /// 6. Fall back to MostViewedPaintings pool if all retries exhausted
  Future<Artwork> getRandomArtwork({
    bool preferLandscape = false,
    List<int>? excludeIds,
  }) async {
    final attemptedThisCall = <String>{};
    for (int attempt = 0; attempt < 5; attempt++) {
      final artwork = await _tryRandomArtistPainting(
        preferLandscape: preferLandscape,
        excludeIds: excludeIds,
        attemptedThisCall: attemptedThisCall,
      );
      if (artwork != null) return artwork;
    }

    // Fallback: existing MostViewedPaintings behaviour
    return _getRandomFromMostViewed(
      preferLandscape: preferLandscape,
      excludeIds: excludeIds,
    );
  }

  /// Single attempt: pick one random artist, return a qualifying painting or null.
  Future<Artwork?> _tryRandomArtistPainting({
    required bool preferLandscape,
    List<int>? excludeIds,
    required Set<String> attemptedThisCall,
  }) async {
    final artists = await getArtistList();
    if (artists.isEmpty) return null;

    // Filter out recently shown artists AND artists tried in this call
    final candidates = artists
        .where((a) => !_recentArtistUrls.contains(a.url) && !attemptedThisCall.contains(a.url))
        .toList();
    final pool = candidates.isNotEmpty ? candidates : artists;

    final artist = pool[_random.nextInt(pool.length)];

    // Mark as attempted immediately (before API call, whether successful or not)
    attemptedThisCall.add(artist.url);

    List<Artwork> paintings;
    try {
      paintings = await getPaintingsByArtist(artist.url);
    } catch (e) {
      debugPrint('[WikiArtService] Failed to fetch paintings for ${artist.url}: $e');
      return null;
    }

    // Resolution filter: longest edge ≥ 1920px
    var usable = paintings.where((p) {
      if (p.width == null || p.height == null) return false;
      return max(p.width!, p.height!) >= 1920;
    }).toList();

    if (preferLandscape) {
      final landscape = usable
          .where((p) => p.width != null && p.height != null && p.width! > p.height!)
          .toList();
      if (landscape.isNotEmpty) usable = landscape;
    }

    if (excludeIds != null) {
      usable = usable.where((p) => !excludeIds.contains(p.contentId)).toList();
    }

    if (usable.isEmpty) return null;

    // Track artist recency
    _recentArtistUrls.add(artist.url);
    if (_recentArtistUrls.length > _recentArtistLimit) {
      _recentArtistUrls.removeAt(0);
    }

    return usable[_random.nextInt(usable.length)];
  }

  /// Fallback: pick from MostViewedPaintings (original behaviour).
  Future<Artwork> _getRandomFromMostViewed({
    required bool preferLandscape,
    List<int>? excludeIds,
  }) async {
    final artworks = await _getOrRefreshIndex();

    var candidates = artworks.where((a) {
      if (excludeIds != null && excludeIds.contains(a.contentId)) return false;
      if (preferLandscape && a.width != null && a.height != null) {
        return a.width! > a.height!;
      }
      return true;
    }).toList();

    if (candidates.isEmpty) candidates = artworks;

    return candidates[_random.nextInt(candidates.length)];
  }

  /// Build/refresh the local artwork index.
  Future<List<Artwork>> _getOrRefreshIndex() async {
    if (_cachedIndex != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedIndex!;
    }

    // Try loading from disk first
    final diskCache = await _loadDiskCache();
    if (diskCache != null) {
      _cachedIndex = diskCache;
      _cacheTimestamp = DateTime.now();
      return _cachedIndex!;
    }

    // Fetch from API
    _cachedIndex = await getMostViewedPaintings();
    _cacheTimestamp = DateTime.now();

    // Persist to disk
    await _saveDiskCache(_cachedIndex!);

    return _cachedIndex!;
  }

  // ──────────────────────────────────────────────
  // Image Download
  // ──────────────────────────────────────────────

  /// Download artwork image to local storage.
  /// Returns the local file path.
  Future<String> downloadImage(Artwork artwork) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/ziba_cache');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    final extension = artwork.image.split('.').last.split('!').first;
    final filename = '${artwork.contentId}.$extension';
    final filepath = '${cacheDir.path}/$filename';

    // Return cached if exists
    if (File(filepath).existsSync()) {
      return filepath;
    }

    // Download
    await _dio.download(artwork.image, filepath);

    // LRU eviction: keep last 30 images
    await _evictOldImages(cacheDir, keep: 30);

    return filepath;
  }

  /// Download an image by URL and contentId to the app cache directory.
  /// Returns the local file path. Returns cached file if already present.
  Future<String> downloadImageUrl(String imageUrl, int contentId) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/ziba_cache');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    final extension = imageUrl.split('.').last.split('!').first;
    final filename = '$contentId.$extension';
    final filepath = '${cacheDir.path}/$filename';

    if (File(filepath).existsSync()) return filepath;

    await _dio.download(imageUrl, filepath);
    await _evictOldImages(cacheDir, keep: 30);
    return filepath;
  }

  Future<void> _evictOldImages(Directory dir, {int keep = 30}) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (files.length > keep) {
      for (final file in files.skip(keep)) {
        file.deleteSync();
      }
    }
  }

  // ──────────────────────────────────────────────
  // Disk Cache (JSON index)
  // ──────────────────────────────────────────────

  Future<String> get _cacheFilePath async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/ziba_index.json';
  }

  Future<String> get _artistsCacheFilePath async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/ziba_artists.json';
  }

  Future<List<Artwork>?> _loadDiskCache() async {
    final path = await _cacheFilePath;
    final file = File(path);
    if (!file.existsSync()) return null;

    // Expire after 7 days
    final modified = file.lastModifiedSync();
    if (DateTime.now().difference(modified) > const Duration(days: 7)) {
      return null;
    }

    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is List) {
        return json
            .map((e) => Artwork.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDiskCache(List<Artwork> artworks) async {
    final path = await _cacheFilePath;
    final json = artworks.map((a) => a.toJson()).toList();
    await File(path).writeAsString(jsonEncode(json));
  }

  Future<List<ArtistSummary>?> _loadArtistDiskCache() async {
    final path = await _artistsCacheFilePath;
    final file = File(path);
    if (!file.existsSync()) return null;

    final modified = file.lastModifiedSync();
    if (DateTime.now().difference(modified) > const Duration(days: 7)) {
      return null;
    }

    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is List) {
        return json
            .map((e) => ArtistSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveArtistDiskCache(List<ArtistSummary> artists) async {
    final path = await _artistsCacheFilePath;
    final json = artists.map((a) => a.toJson()).toList();
    await File(path).writeAsString(jsonEncode(json));
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  List<Artwork> _parsePaintingList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Artwork.fromJson(e))
          .where((a) => a.image.isNotEmpty)
          .toList();
    }
    return [];
  }
}
