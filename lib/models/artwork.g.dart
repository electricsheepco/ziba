// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtworkImpl _$$ArtworkImplFromJson(Map<String, dynamic> json) =>
    _$ArtworkImpl(
      contentId: (json['contentId'] as num).toInt(),
      title: json['title'] as String,
      artistName: json['artistName'] as String,
      artistUrl: json['artistUrl'] as String?,
      completitionYear: (json['completitionYear'] as num?)?.toInt(),
      yearAsString: json['yearAsString'] as String?,
      image: json['image'] as String,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      genre: json['genre'] as String?,
      style: json['style'] as String?,
      technique: json['technique'] as String?,
      galleryName: json['galleryName'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      setAt: json['setAt'] == null
          ? null
          : DateTime.parse(json['setAt'] as String),
    );

Map<String, dynamic> _$$ArtworkImplToJson(_$ArtworkImpl instance) =>
    <String, dynamic>{
      'contentId': instance.contentId,
      'title': instance.title,
      'artistName': instance.artistName,
      'artistUrl': instance.artistUrl,
      'completitionYear': instance.completitionYear,
      'yearAsString': instance.yearAsString,
      'image': instance.image,
      'width': instance.width,
      'height': instance.height,
      'genre': instance.genre,
      'style': instance.style,
      'technique': instance.technique,
      'galleryName': instance.galleryName,
      'isFavorite': instance.isFavorite,
      'setAt': instance.setAt?.toIso8601String(),
    };

_$ArtistSummaryImpl _$$ArtistSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ArtistSummaryImpl(
      url: json['url'] as String,
      artistName: json['artistName'] as String,
      birthDay: null, // API returns /Date(ms)/ string format — not used
      deathDay: null, // API returns /Date(ms)/ string format — not used
      image: json['image'] as String?,
      nationality: json['nationality'] as String?,
    );

Map<String, dynamic> _$$ArtistSummaryImplToJson(_$ArtistSummaryImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'artistName': instance.artistName,
      'birthDay': instance.birthDay,
      'deathDay': instance.deathDay,
      'image': instance.image,
      'nationality': instance.nationality,
    };
