import 'package:ziba/data/database.dart' as db_row;
import 'package:ziba/models/artwork.dart' as freezed_model;

/// Lightweight value object passed between screens.
///
/// Decouples UI from both the Freezed API model and the Drift DB row type.
class ArtworkData {
  final int contentId;
  final String title;
  final String artistName;
  final int? completitionYear;
  final String imageUrl;
  final String? localPath;
  final int? width;
  final int? height;
  final String? style; // art movement (Impressionism, Baroque, etc.)

  const ArtworkData({
    required this.contentId,
    required this.title,
    required this.artistName,
    this.completitionYear,
    required this.imageUrl,
    this.localPath,
    this.width,
    this.height,
    this.style,
  });

  /// From Freezed API model (used on HomeScreen after fetch).
  factory ArtworkData.fromModel(
    freezed_model.Artwork artwork, {
    String? localPath,
  }) =>
      ArtworkData(
        contentId: artwork.contentId,
        title: artwork.title,
        artistName: artwork.artistName,
        completitionYear: artwork.completitionYear,
        imageUrl: artwork.image,
        localPath: localPath,
        width: artwork.width,
        height: artwork.height,
        style: artwork.style,
      );

  /// From Drift DB row (used on History/FavoritesScreen).
  factory ArtworkData.fromRow(db_row.Artwork row) => ArtworkData(
        contentId: row.contentId,
        title: row.title,
        artistName: row.artistName,
        completitionYear: row.completitionYear,
        imageUrl: row.imageUrl,
        localPath: row.localPath,
        width: row.width,
        height: row.height,
        style: row.style,
      );
}
