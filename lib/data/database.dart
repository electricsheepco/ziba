import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ──────────────────────────────────────────────
// Table Definitions
// ──────────────────────────────────────────────

class Artworks extends Table {
  IntColumn get contentId => integer()();
  TextColumn get title => text()();
  TextColumn get artistName => text()();
  TextColumn get artistUrl => text().nullable()();
  IntColumn get completitionYear => integer().nullable()();
  TextColumn get imageUrl => text()();
  TextColumn get localPath => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get style => text().nullable()();

  @override
  Set<Column> get primaryKey => {contentId};
}

class WallpaperHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contentId => integer().references(Artworks, #contentId)();
  DateTimeColumn get setAt => dateTime().withDefault(currentDateAndTime)();
}

class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contentId => integer().references(Artworks, #contentId)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {contentId}
      ];
}

// ──────────────────────────────────────────────
// Database
// ──────────────────────────────────────────────

@DriftDatabase(tables: [Artworks, WallpaperHistory, Favorites])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Artwork CRUD ──

  Future<void> upsertArtwork(ArtworksCompanion artwork) =>
      into(artworks).insertOnConflictUpdate(artwork);

  Future<Artwork?> getArtwork(int contentId) =>
      (select(artworks)..where((a) => a.contentId.equals(contentId)))
          .getSingleOrNull();

  // ── History ──

  Future<void> addToHistory(int contentId) async {
    await into(wallpaperHistory).insert(WallpaperHistoryCompanion.insert(
      contentId: contentId,
    ));
  }

  Stream<List<WallpaperHistoryWithArtwork>> watchHistory({int limit = 50}) {
    final query = select(wallpaperHistory).join([
      innerJoin(artworks,
          artworks.contentId.equalsExp(wallpaperHistory.contentId)),
    ])
      ..orderBy([OrderingTerm.desc(wallpaperHistory.setAt)])
      ..limit(limit);

    return query.watch().map((rows) => rows.map((row) {
          return WallpaperHistoryWithArtwork(
            history: row.readTable(wallpaperHistory),
            artwork: row.readTable(artworks),
          );
        }).toList());
  }

  /// Get list of contentIds from recent history (for exclusion in random picks).
  Future<List<int>> getRecentHistoryIds({int limit = 30}) async {
    final query = select(wallpaperHistory)
      ..orderBy([(h) => OrderingTerm.desc(h.setAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((r) => r.contentId).toList();
  }

  // ── Favorites ──

  Future<void> addFavorite(int contentId) => into(favorites).insert(
        FavoritesCompanion.insert(contentId: contentId),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> removeFavorite(int contentId) =>
      (delete(favorites)..where((f) => f.contentId.equals(contentId))).go();

  Future<bool> isFavorite(int contentId) async {
    final row = await (select(favorites)
          ..where((f) => f.contentId.equals(contentId)))
        .getSingleOrNull();
    return row != null;
  }

  Stream<bool> watchIsFavorite(int contentId) {
    return (select(favorites)..where((f) => f.contentId.equals(contentId)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  Stream<List<Artwork>> watchFavorites() {
    final query = select(favorites).join([
      innerJoin(artworks, artworks.contentId.equalsExp(favorites.contentId)),
    ])
      ..orderBy([OrderingTerm.desc(favorites.addedAt)]);

    return query.watch().map(
        (rows) => rows.map((row) => row.readTable(artworks)).toList());
  }
}

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

class WallpaperHistoryWithArtwork {
  final WallpaperHistoryData history;
  final Artwork artwork;

  WallpaperHistoryWithArtwork({
    required this.history,
    required this.artwork,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'ziba.db'));
    return NativeDatabase.createInBackground(file);
  });
}
