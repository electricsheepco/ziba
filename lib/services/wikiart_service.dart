import 'dart:math';
import 'package:dio/dio.dart';
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
  /// Strategy:
  /// 1. Use cached "most viewed" list for fast picks
  /// 2. Filter for landscape orientation (width > height) on desktop
  /// 3. Prefer high-resolution images
  Future<Artwork> getRandomArtwork({
    bool preferLandscape = false,
    List<int>? excludeIds,
  }) async {
    final artworks = await _getOrRefreshIndex();

    var candidates = artworks.where((a) {
      // Exclude already-shown
      if (excludeIds != null && excludeIds.contains(a.contentId)) {
        return false;
      }
      // Filter orientation
      if (preferLandscape && a.width != null && a.height != null) {
        return a.width! > a.height!;
      }
      return true;
    }).toList();

    if (candidates.isEmpty) {
      // Reset: if we've exhausted the pool, use full list
      candidates = artworks;
    }

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

  Future<List<Artwork>?> _loadDiskCache() async {
    final path = await _cacheFilePath;
    final file = File(path);
    if (!file.existsSync()) return null;

    // Expire after 7 days
    final modified = file.lastModifiedSync();
    if (DateTime.now().difference(modified) > const Duration(days: 7)) {
      return null;
    }

    final json = jsonDecode(file.readAsStringSync());
    if (json is List) {
      return json
          .map((e) => Artwork.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Future<void> _saveDiskCache(List<Artwork> artworks) async {
    final path = await _cacheFilePath;
    final json = artworks.map((a) => a.toJson()).toList();
    File(path).writeAsStringSync(jsonEncode(json));
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
