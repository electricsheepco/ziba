// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artwork.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Artwork _$ArtworkFromJson(Map<String, dynamic> json) {
  return _Artwork.fromJson(json);
}

/// @nodoc
mixin _$Artwork {
  int get contentId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get artistName => throw _privateConstructorUsedError;
  String? get artistUrl => throw _privateConstructorUsedError;
  int? get completitionYear => throw _privateConstructorUsedError;
  String? get yearAsString => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  String? get genre => throw _privateConstructorUsedError;
  String? get style => throw _privateConstructorUsedError;
  String? get technique => throw _privateConstructorUsedError;
  String? get galleryName => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  DateTime? get setAt => throw _privateConstructorUsedError;

  /// Serializes this Artwork to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Artwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtworkCopyWith<Artwork> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtworkCopyWith<$Res> {
  factory $ArtworkCopyWith(Artwork value, $Res Function(Artwork) then) =
      _$ArtworkCopyWithImpl<$Res, Artwork>;
  @useResult
  $Res call(
      {int contentId,
      String title,
      String artistName,
      String? artistUrl,
      int? completitionYear,
      String? yearAsString,
      String image,
      int? width,
      int? height,
      String? genre,
      String? style,
      String? technique,
      String? galleryName,
      bool isFavorite,
      DateTime? setAt});
}

/// @nodoc
class _$ArtworkCopyWithImpl<$Res, $Val extends Artwork>
    implements $ArtworkCopyWith<$Res> {
  _$ArtworkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Artwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? title = null,
    Object? artistName = null,
    Object? artistUrl = freezed,
    Object? completitionYear = freezed,
    Object? yearAsString = freezed,
    Object? image = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? genre = freezed,
    Object? style = freezed,
    Object? technique = freezed,
    Object? galleryName = freezed,
    Object? isFavorite = null,
    Object? setAt = freezed,
  }) {
    return _then(_value.copyWith(
      contentId: null == contentId
          ? _value.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artistName: null == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String,
      artistUrl: freezed == artistUrl
          ? _value.artistUrl
          : artistUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      completitionYear: freezed == completitionYear
          ? _value.completitionYear
          : completitionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      yearAsString: freezed == yearAsString
          ? _value.yearAsString
          : yearAsString // ignore: cast_nullable_to_non_nullable
              as String?,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      genre: freezed == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String?,
      technique: freezed == technique
          ? _value.technique
          : technique // ignore: cast_nullable_to_non_nullable
              as String?,
      galleryName: freezed == galleryName
          ? _value.galleryName
          : galleryName // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      setAt: freezed == setAt
          ? _value.setAt
          : setAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtworkImplCopyWith<$Res> implements $ArtworkCopyWith<$Res> {
  factory _$$ArtworkImplCopyWith(
          _$ArtworkImpl value, $Res Function(_$ArtworkImpl) then) =
      __$$ArtworkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int contentId,
      String title,
      String artistName,
      String? artistUrl,
      int? completitionYear,
      String? yearAsString,
      String image,
      int? width,
      int? height,
      String? genre,
      String? style,
      String? technique,
      String? galleryName,
      bool isFavorite,
      DateTime? setAt});
}

/// @nodoc
class __$$ArtworkImplCopyWithImpl<$Res>
    extends _$ArtworkCopyWithImpl<$Res, _$ArtworkImpl>
    implements _$$ArtworkImplCopyWith<$Res> {
  __$$ArtworkImplCopyWithImpl(
      _$ArtworkImpl _value, $Res Function(_$ArtworkImpl) _then)
      : super(_value, _then);

  /// Create a copy of Artwork
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contentId = null,
    Object? title = null,
    Object? artistName = null,
    Object? artistUrl = freezed,
    Object? completitionYear = freezed,
    Object? yearAsString = freezed,
    Object? image = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? genre = freezed,
    Object? style = freezed,
    Object? technique = freezed,
    Object? galleryName = freezed,
    Object? isFavorite = null,
    Object? setAt = freezed,
  }) {
    return _then(_$ArtworkImpl(
      contentId: null == contentId
          ? _value.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artistName: null == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String,
      artistUrl: freezed == artistUrl
          ? _value.artistUrl
          : artistUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      completitionYear: freezed == completitionYear
          ? _value.completitionYear
          : completitionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      yearAsString: freezed == yearAsString
          ? _value.yearAsString
          : yearAsString // ignore: cast_nullable_to_non_nullable
              as String?,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      genre: freezed == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String?,
      technique: freezed == technique
          ? _value.technique
          : technique // ignore: cast_nullable_to_non_nullable
              as String?,
      galleryName: freezed == galleryName
          ? _value.galleryName
          : galleryName // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      setAt: freezed == setAt
          ? _value.setAt
          : setAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtworkImpl implements _Artwork {
  const _$ArtworkImpl(
      {required this.contentId,
      required this.title,
      required this.artistName,
      this.artistUrl,
      this.completitionYear,
      this.yearAsString,
      required this.image,
      this.width,
      this.height,
      this.genre,
      this.style,
      this.technique,
      this.galleryName,
      this.isFavorite = false,
      this.setAt});

  factory _$ArtworkImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtworkImplFromJson(json);

  @override
  final int contentId;
  @override
  final String title;
  @override
  final String artistName;
  @override
  final String? artistUrl;
  @override
  final int? completitionYear;
  @override
  final String? yearAsString;
  @override
  final String image;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final String? genre;
  @override
  final String? style;
  @override
  final String? technique;
  @override
  final String? galleryName;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  final DateTime? setAt;

  @override
  String toString() {
    return 'Artwork(contentId: $contentId, title: $title, artistName: $artistName, artistUrl: $artistUrl, completitionYear: $completitionYear, yearAsString: $yearAsString, image: $image, width: $width, height: $height, genre: $genre, style: $style, technique: $technique, galleryName: $galleryName, isFavorite: $isFavorite, setAt: $setAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtworkImpl &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artistName, artistName) ||
                other.artistName == artistName) &&
            (identical(other.artistUrl, artistUrl) ||
                other.artistUrl == artistUrl) &&
            (identical(other.completitionYear, completitionYear) ||
                other.completitionYear == completitionYear) &&
            (identical(other.yearAsString, yearAsString) ||
                other.yearAsString == yearAsString) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.technique, technique) ||
                other.technique == technique) &&
            (identical(other.galleryName, galleryName) ||
                other.galleryName == galleryName) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.setAt, setAt) || other.setAt == setAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      contentId,
      title,
      artistName,
      artistUrl,
      completitionYear,
      yearAsString,
      image,
      width,
      height,
      genre,
      style,
      technique,
      galleryName,
      isFavorite,
      setAt);

  /// Create a copy of Artwork
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtworkImplCopyWith<_$ArtworkImpl> get copyWith =>
      __$$ArtworkImplCopyWithImpl<_$ArtworkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtworkImplToJson(
      this,
    );
  }
}

abstract class _Artwork implements Artwork {
  const factory _Artwork(
      {required final int contentId,
      required final String title,
      required final String artistName,
      final String? artistUrl,
      final int? completitionYear,
      final String? yearAsString,
      required final String image,
      final int? width,
      final int? height,
      final String? genre,
      final String? style,
      final String? technique,
      final String? galleryName,
      final bool isFavorite,
      final DateTime? setAt}) = _$ArtworkImpl;

  factory _Artwork.fromJson(Map<String, dynamic> json) = _$ArtworkImpl.fromJson;

  @override
  int get contentId;
  @override
  String get title;
  @override
  String get artistName;
  @override
  String? get artistUrl;
  @override
  int? get completitionYear;
  @override
  String? get yearAsString;
  @override
  String get image;
  @override
  int? get width;
  @override
  int? get height;
  @override
  String? get genre;
  @override
  String? get style;
  @override
  String? get technique;
  @override
  String? get galleryName;
  @override
  bool get isFavorite;
  @override
  DateTime? get setAt;

  /// Create a copy of Artwork
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtworkImplCopyWith<_$ArtworkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistSummary _$ArtistSummaryFromJson(Map<String, dynamic> json) {
  return _ArtistSummary.fromJson(json);
}

/// @nodoc
mixin _$ArtistSummary {
  String get url => throw _privateConstructorUsedError;
  String get artistName => throw _privateConstructorUsedError;
  int? get birthDay => throw _privateConstructorUsedError;
  int? get deathDay => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  String? get nationality => throw _privateConstructorUsedError;

  /// Serializes this ArtistSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistSummaryCopyWith<ArtistSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistSummaryCopyWith<$Res> {
  factory $ArtistSummaryCopyWith(
          ArtistSummary value, $Res Function(ArtistSummary) then) =
      _$ArtistSummaryCopyWithImpl<$Res, ArtistSummary>;
  @useResult
  $Res call(
      {String url,
      String artistName,
      int? birthDay,
      int? deathDay,
      String? image,
      String? nationality});
}

/// @nodoc
class _$ArtistSummaryCopyWithImpl<$Res, $Val extends ArtistSummary>
    implements $ArtistSummaryCopyWith<$Res> {
  _$ArtistSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? artistName = null,
    Object? birthDay = freezed,
    Object? deathDay = freezed,
    Object? image = freezed,
    Object? nationality = freezed,
  }) {
    return _then(_value.copyWith(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      artistName: null == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String,
      birthDay: freezed == birthDay
          ? _value.birthDay
          : birthDay // ignore: cast_nullable_to_non_nullable
              as int?,
      deathDay: freezed == deathDay
          ? _value.deathDay
          : deathDay // ignore: cast_nullable_to_non_nullable
              as int?,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistSummaryImplCopyWith<$Res>
    implements $ArtistSummaryCopyWith<$Res> {
  factory _$$ArtistSummaryImplCopyWith(
          _$ArtistSummaryImpl value, $Res Function(_$ArtistSummaryImpl) then) =
      __$$ArtistSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String url,
      String artistName,
      int? birthDay,
      int? deathDay,
      String? image,
      String? nationality});
}

/// @nodoc
class __$$ArtistSummaryImplCopyWithImpl<$Res>
    extends _$ArtistSummaryCopyWithImpl<$Res, _$ArtistSummaryImpl>
    implements _$$ArtistSummaryImplCopyWith<$Res> {
  __$$ArtistSummaryImplCopyWithImpl(
      _$ArtistSummaryImpl _value, $Res Function(_$ArtistSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? artistName = null,
    Object? birthDay = freezed,
    Object? deathDay = freezed,
    Object? image = freezed,
    Object? nationality = freezed,
  }) {
    return _then(_$ArtistSummaryImpl(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      artistName: null == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String,
      birthDay: freezed == birthDay
          ? _value.birthDay
          : birthDay // ignore: cast_nullable_to_non_nullable
              as int?,
      deathDay: freezed == deathDay
          ? _value.deathDay
          : deathDay // ignore: cast_nullable_to_non_nullable
              as int?,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      nationality: freezed == nationality
          ? _value.nationality
          : nationality // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistSummaryImpl implements _ArtistSummary {
  const _$ArtistSummaryImpl(
      {required this.url,
      required this.artistName,
      this.birthDay,
      this.deathDay,
      this.image,
      this.nationality});

  factory _$ArtistSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistSummaryImplFromJson(json);

  @override
  final String url;
  @override
  final String artistName;
  @override
  final int? birthDay;
  @override
  final int? deathDay;
  @override
  final String? image;
  @override
  final String? nationality;

  @override
  String toString() {
    return 'ArtistSummary(url: $url, artistName: $artistName, birthDay: $birthDay, deathDay: $deathDay, image: $image, nationality: $nationality)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistSummaryImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.artistName, artistName) ||
                other.artistName == artistName) &&
            (identical(other.birthDay, birthDay) ||
                other.birthDay == birthDay) &&
            (identical(other.deathDay, deathDay) ||
                other.deathDay == deathDay) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.nationality, nationality) ||
                other.nationality == nationality));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, url, artistName, birthDay, deathDay, image, nationality);

  /// Create a copy of ArtistSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistSummaryImplCopyWith<_$ArtistSummaryImpl> get copyWith =>
      __$$ArtistSummaryImplCopyWithImpl<_$ArtistSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistSummaryImplToJson(
      this,
    );
  }
}

abstract class _ArtistSummary implements ArtistSummary {
  const factory _ArtistSummary(
      {required final String url,
      required final String artistName,
      final int? birthDay,
      final int? deathDay,
      final String? image,
      final String? nationality}) = _$ArtistSummaryImpl;

  factory _ArtistSummary.fromJson(Map<String, dynamic> json) =
      _$ArtistSummaryImpl.fromJson;

  @override
  String get url;
  @override
  String get artistName;
  @override
  int? get birthDay;
  @override
  int? get deathDay;
  @override
  String? get image;
  @override
  String? get nationality;

  /// Create a copy of ArtistSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistSummaryImplCopyWith<_$ArtistSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
