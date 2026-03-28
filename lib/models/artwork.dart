import 'package:freezed_annotation/freezed_annotation.dart';

part 'artwork.freezed.dart';
part 'artwork.g.dart';

@freezed
class Artwork with _$Artwork {
  const factory Artwork({
    required int contentId,
    required String title,
    required String artistName,
    String? artistUrl,
    int? completitionYear,
    String? yearAsString,
    required String image,
    int? width,
    int? height,
    String? genre,
    String? style,
    String? technique,
    String? galleryName,
    @Default(false) bool isFavorite,
    DateTime? setAt, // when it was set as wallpaper
  }) = _Artwork;

  factory Artwork.fromJson(Map<String, dynamic> json) =>
      _$ArtworkFromJson(json);
}

@freezed
class ArtistSummary with _$ArtistSummary {
  const factory ArtistSummary({
    required String url,
    required String artistName,
    int? birthDay,
    int? deathDay,
    String? image,
    String? nationality,
  }) = _ArtistSummary;

  factory ArtistSummary.fromJson(Map<String, dynamic> json) =>
      _$ArtistSummaryFromJson(json);
}
