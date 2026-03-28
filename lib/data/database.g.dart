// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ArtworksTable extends Artworks with TableInfo<$ArtworksTable, Artwork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentIdMeta =
      const VerificationMeta('contentId');
  @override
  late final GeneratedColumn<int> contentId = GeneratedColumn<int>(
      'content_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistNameMeta =
      const VerificationMeta('artistName');
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
      'artist_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistUrlMeta =
      const VerificationMeta('artistUrl');
  @override
  late final GeneratedColumn<String> artistUrl = GeneratedColumn<String>(
      'artist_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completitionYearMeta =
      const VerificationMeta('completitionYear');
  @override
  late final GeneratedColumn<int> completitionYear = GeneratedColumn<int>(
      'completition_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
      'style', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        contentId,
        title,
        artistName,
        artistUrl,
        completitionYear,
        imageUrl,
        localPath,
        width,
        height,
        genre,
        style
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artworks';
  @override
  VerificationContext validateIntegrity(Insertable<Artwork> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta,
          contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
          _artistNameMeta,
          artistName.isAcceptableOrUnknown(
              data['artist_name']!, _artistNameMeta));
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('artist_url')) {
      context.handle(_artistUrlMeta,
          artistUrl.isAcceptableOrUnknown(data['artist_url']!, _artistUrlMeta));
    }
    if (data.containsKey('completition_year')) {
      context.handle(
          _completitionYearMeta,
          completitionYear.isAcceptableOrUnknown(
              data['completition_year']!, _completitionYearMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    } else if (isInserting) {
      context.missing(_imageUrlMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('style')) {
      context.handle(
          _styleMeta, style.isAcceptableOrUnknown(data['style']!, _styleMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentId};
  @override
  Artwork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artwork(
      contentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artistName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_name'])!,
      artistUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_url']),
      completitionYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completition_year']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      style: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}style']),
    );
  }

  @override
  $ArtworksTable createAlias(String alias) {
    return $ArtworksTable(attachedDatabase, alias);
  }
}

class Artwork extends DataClass implements Insertable<Artwork> {
  final int contentId;
  final String title;
  final String artistName;
  final String? artistUrl;
  final int? completitionYear;
  final String imageUrl;
  final String? localPath;
  final int? width;
  final int? height;
  final String? genre;
  final String? style;
  const Artwork(
      {required this.contentId,
      required this.title,
      required this.artistName,
      this.artistUrl,
      this.completitionYear,
      required this.imageUrl,
      this.localPath,
      this.width,
      this.height,
      this.genre,
      this.style});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_id'] = Variable<int>(contentId);
    map['title'] = Variable<String>(title);
    map['artist_name'] = Variable<String>(artistName);
    if (!nullToAbsent || artistUrl != null) {
      map['artist_url'] = Variable<String>(artistUrl);
    }
    if (!nullToAbsent || completitionYear != null) {
      map['completition_year'] = Variable<int>(completitionYear);
    }
    map['image_url'] = Variable<String>(imageUrl);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || style != null) {
      map['style'] = Variable<String>(style);
    }
    return map;
  }

  ArtworksCompanion toCompanion(bool nullToAbsent) {
    return ArtworksCompanion(
      contentId: Value(contentId),
      title: Value(title),
      artistName: Value(artistName),
      artistUrl: artistUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artistUrl),
      completitionYear: completitionYear == null && nullToAbsent
          ? const Value.absent()
          : Value(completitionYear),
      imageUrl: Value(imageUrl),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      style:
          style == null && nullToAbsent ? const Value.absent() : Value(style),
    );
  }

  factory Artwork.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artwork(
      contentId: serializer.fromJson<int>(json['contentId']),
      title: serializer.fromJson<String>(json['title']),
      artistName: serializer.fromJson<String>(json['artistName']),
      artistUrl: serializer.fromJson<String?>(json['artistUrl']),
      completitionYear: serializer.fromJson<int?>(json['completitionYear']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      genre: serializer.fromJson<String?>(json['genre']),
      style: serializer.fromJson<String?>(json['style']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentId': serializer.toJson<int>(contentId),
      'title': serializer.toJson<String>(title),
      'artistName': serializer.toJson<String>(artistName),
      'artistUrl': serializer.toJson<String?>(artistUrl),
      'completitionYear': serializer.toJson<int?>(completitionYear),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'localPath': serializer.toJson<String?>(localPath),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'genre': serializer.toJson<String?>(genre),
      'style': serializer.toJson<String?>(style),
    };
  }

  Artwork copyWith(
          {int? contentId,
          String? title,
          String? artistName,
          Value<String?> artistUrl = const Value.absent(),
          Value<int?> completitionYear = const Value.absent(),
          String? imageUrl,
          Value<String?> localPath = const Value.absent(),
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<String?> genre = const Value.absent(),
          Value<String?> style = const Value.absent()}) =>
      Artwork(
        contentId: contentId ?? this.contentId,
        title: title ?? this.title,
        artistName: artistName ?? this.artistName,
        artistUrl: artistUrl.present ? artistUrl.value : this.artistUrl,
        completitionYear: completitionYear.present
            ? completitionYear.value
            : this.completitionYear,
        imageUrl: imageUrl ?? this.imageUrl,
        localPath: localPath.present ? localPath.value : this.localPath,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        genre: genre.present ? genre.value : this.genre,
        style: style.present ? style.value : this.style,
      );
  Artwork copyWithCompanion(ArtworksCompanion data) {
    return Artwork(
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      title: data.title.present ? data.title.value : this.title,
      artistName:
          data.artistName.present ? data.artistName.value : this.artistName,
      artistUrl: data.artistUrl.present ? data.artistUrl.value : this.artistUrl,
      completitionYear: data.completitionYear.present
          ? data.completitionYear.value
          : this.completitionYear,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      genre: data.genre.present ? data.genre.value : this.genre,
      style: data.style.present ? data.style.value : this.style,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artwork(')
          ..write('contentId: $contentId, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('artistUrl: $artistUrl, ')
          ..write('completitionYear: $completitionYear, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localPath: $localPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('genre: $genre, ')
          ..write('style: $style')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contentId, title, artistName, artistUrl,
      completitionYear, imageUrl, localPath, width, height, genre, style);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artwork &&
          other.contentId == this.contentId &&
          other.title == this.title &&
          other.artistName == this.artistName &&
          other.artistUrl == this.artistUrl &&
          other.completitionYear == this.completitionYear &&
          other.imageUrl == this.imageUrl &&
          other.localPath == this.localPath &&
          other.width == this.width &&
          other.height == this.height &&
          other.genre == this.genre &&
          other.style == this.style);
}

class ArtworksCompanion extends UpdateCompanion<Artwork> {
  final Value<int> contentId;
  final Value<String> title;
  final Value<String> artistName;
  final Value<String?> artistUrl;
  final Value<int?> completitionYear;
  final Value<String> imageUrl;
  final Value<String?> localPath;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> genre;
  final Value<String?> style;
  const ArtworksCompanion({
    this.contentId = const Value.absent(),
    this.title = const Value.absent(),
    this.artistName = const Value.absent(),
    this.artistUrl = const Value.absent(),
    this.completitionYear = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.genre = const Value.absent(),
    this.style = const Value.absent(),
  });
  ArtworksCompanion.insert({
    this.contentId = const Value.absent(),
    required String title,
    required String artistName,
    this.artistUrl = const Value.absent(),
    this.completitionYear = const Value.absent(),
    required String imageUrl,
    this.localPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.genre = const Value.absent(),
    this.style = const Value.absent(),
  })  : title = Value(title),
        artistName = Value(artistName),
        imageUrl = Value(imageUrl);
  static Insertable<Artwork> custom({
    Expression<int>? contentId,
    Expression<String>? title,
    Expression<String>? artistName,
    Expression<String>? artistUrl,
    Expression<int>? completitionYear,
    Expression<String>? imageUrl,
    Expression<String>? localPath,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? genre,
    Expression<String>? style,
  }) {
    return RawValuesInsertable({
      if (contentId != null) 'content_id': contentId,
      if (title != null) 'title': title,
      if (artistName != null) 'artist_name': artistName,
      if (artistUrl != null) 'artist_url': artistUrl,
      if (completitionYear != null) 'completition_year': completitionYear,
      if (imageUrl != null) 'image_url': imageUrl,
      if (localPath != null) 'local_path': localPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (genre != null) 'genre': genre,
      if (style != null) 'style': style,
    });
  }

  ArtworksCompanion copyWith(
      {Value<int>? contentId,
      Value<String>? title,
      Value<String>? artistName,
      Value<String?>? artistUrl,
      Value<int?>? completitionYear,
      Value<String>? imageUrl,
      Value<String?>? localPath,
      Value<int?>? width,
      Value<int?>? height,
      Value<String?>? genre,
      Value<String?>? style}) {
    return ArtworksCompanion(
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      artistUrl: artistUrl ?? this.artistUrl,
      completitionYear: completitionYear ?? this.completitionYear,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      width: width ?? this.width,
      height: height ?? this.height,
      genre: genre ?? this.genre,
      style: style ?? this.style,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentId.present) {
      map['content_id'] = Variable<int>(contentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (artistUrl.present) {
      map['artist_url'] = Variable<String>(artistUrl.value);
    }
    if (completitionYear.present) {
      map['completition_year'] = Variable<int>(completitionYear.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworksCompanion(')
          ..write('contentId: $contentId, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('artistUrl: $artistUrl, ')
          ..write('completitionYear: $completitionYear, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localPath: $localPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('genre: $genre, ')
          ..write('style: $style')
          ..write(')'))
        .toString();
  }
}

class $WallpaperHistoryTable extends WallpaperHistory
    with TableInfo<$WallpaperHistoryTable, WallpaperHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WallpaperHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contentIdMeta =
      const VerificationMeta('contentId');
  @override
  late final GeneratedColumn<int> contentId = GeneratedColumn<int>(
      'content_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES artworks (content_id)'));
  static const VerificationMeta _setAtMeta = const VerificationMeta('setAt');
  @override
  late final GeneratedColumn<DateTime> setAt = GeneratedColumn<DateTime>(
      'set_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, contentId, setAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallpaper_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<WallpaperHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta,
          contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('set_at')) {
      context.handle(
          _setAtMeta, setAt.isAcceptableOrUnknown(data['set_at']!, _setAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WallpaperHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WallpaperHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      contentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_id'])!,
      setAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}set_at'])!,
    );
  }

  @override
  $WallpaperHistoryTable createAlias(String alias) {
    return $WallpaperHistoryTable(attachedDatabase, alias);
  }
}

class WallpaperHistoryData extends DataClass
    implements Insertable<WallpaperHistoryData> {
  final int id;
  final int contentId;
  final DateTime setAt;
  const WallpaperHistoryData(
      {required this.id, required this.contentId, required this.setAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content_id'] = Variable<int>(contentId);
    map['set_at'] = Variable<DateTime>(setAt);
    return map;
  }

  WallpaperHistoryCompanion toCompanion(bool nullToAbsent) {
    return WallpaperHistoryCompanion(
      id: Value(id),
      contentId: Value(contentId),
      setAt: Value(setAt),
    );
  }

  factory WallpaperHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WallpaperHistoryData(
      id: serializer.fromJson<int>(json['id']),
      contentId: serializer.fromJson<int>(json['contentId']),
      setAt: serializer.fromJson<DateTime>(json['setAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contentId': serializer.toJson<int>(contentId),
      'setAt': serializer.toJson<DateTime>(setAt),
    };
  }

  WallpaperHistoryData copyWith({int? id, int? contentId, DateTime? setAt}) =>
      WallpaperHistoryData(
        id: id ?? this.id,
        contentId: contentId ?? this.contentId,
        setAt: setAt ?? this.setAt,
      );
  WallpaperHistoryData copyWithCompanion(WallpaperHistoryCompanion data) {
    return WallpaperHistoryData(
      id: data.id.present ? data.id.value : this.id,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      setAt: data.setAt.present ? data.setAt.value : this.setAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WallpaperHistoryData(')
          ..write('id: $id, ')
          ..write('contentId: $contentId, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contentId, setAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WallpaperHistoryData &&
          other.id == this.id &&
          other.contentId == this.contentId &&
          other.setAt == this.setAt);
}

class WallpaperHistoryCompanion extends UpdateCompanion<WallpaperHistoryData> {
  final Value<int> id;
  final Value<int> contentId;
  final Value<DateTime> setAt;
  const WallpaperHistoryCompanion({
    this.id = const Value.absent(),
    this.contentId = const Value.absent(),
    this.setAt = const Value.absent(),
  });
  WallpaperHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int contentId,
    this.setAt = const Value.absent(),
  }) : contentId = Value(contentId);
  static Insertable<WallpaperHistoryData> custom({
    Expression<int>? id,
    Expression<int>? contentId,
    Expression<DateTime>? setAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentId != null) 'content_id': contentId,
      if (setAt != null) 'set_at': setAt,
    });
  }

  WallpaperHistoryCompanion copyWith(
      {Value<int>? id, Value<int>? contentId, Value<DateTime>? setAt}) {
    return WallpaperHistoryCompanion(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      setAt: setAt ?? this.setAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<int>(contentId.value);
    }
    if (setAt.present) {
      map['set_at'] = Variable<DateTime>(setAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WallpaperHistoryCompanion(')
          ..write('id: $id, ')
          ..write('contentId: $contentId, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contentIdMeta =
      const VerificationMeta('contentId');
  @override
  late final GeneratedColumn<int> contentId = GeneratedColumn<int>(
      'content_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES artworks (content_id)'));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, contentId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(Insertable<Favorite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content_id')) {
      context.handle(_contentIdMeta,
          contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta));
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {contentId},
      ];
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      contentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_id'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final int contentId;
  final DateTime addedAt;
  const Favorite(
      {required this.id, required this.contentId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content_id'] = Variable<int>(contentId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      contentId: Value(contentId),
      addedAt: Value(addedAt),
    );
  }

  factory Favorite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      contentId: serializer.fromJson<int>(json['contentId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contentId': serializer.toJson<int>(contentId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith({int? id, int? contentId, DateTime? addedAt}) => Favorite(
        id: id ?? this.id,
        contentId: contentId ?? this.contentId,
        addedAt: addedAt ?? this.addedAt,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('contentId: $contentId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contentId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.contentId == this.contentId &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<int> contentId;
  final Value<DateTime> addedAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.contentId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required int contentId,
    this.addedAt = const Value.absent(),
  }) : contentId = Value(contentId);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<int>? contentId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentId != null) 'content_id': contentId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith(
      {Value<int>? id, Value<int>? contentId, Value<DateTime>? addedAt}) {
    return FavoritesCompanion(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<int>(contentId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('contentId: $contentId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArtworksTable artworks = $ArtworksTable(this);
  late final $WallpaperHistoryTable wallpaperHistory =
      $WallpaperHistoryTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [artworks, wallpaperHistory, favorites];
}

typedef $$ArtworksTableCreateCompanionBuilder = ArtworksCompanion Function({
  Value<int> contentId,
  required String title,
  required String artistName,
  Value<String?> artistUrl,
  Value<int?> completitionYear,
  required String imageUrl,
  Value<String?> localPath,
  Value<int?> width,
  Value<int?> height,
  Value<String?> genre,
  Value<String?> style,
});
typedef $$ArtworksTableUpdateCompanionBuilder = ArtworksCompanion Function({
  Value<int> contentId,
  Value<String> title,
  Value<String> artistName,
  Value<String?> artistUrl,
  Value<int?> completitionYear,
  Value<String> imageUrl,
  Value<String?> localPath,
  Value<int?> width,
  Value<int?> height,
  Value<String?> genre,
  Value<String?> style,
});

final class $$ArtworksTableReferences
    extends BaseReferences<_$AppDatabase, $ArtworksTable, Artwork> {
  $$ArtworksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WallpaperHistoryTable, List<WallpaperHistoryData>>
      _wallpaperHistoryRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.wallpaperHistory,
              aliasName: $_aliasNameGenerator(
                  db.artworks.contentId, db.wallpaperHistory.contentId));

  $$WallpaperHistoryTableProcessedTableManager get wallpaperHistoryRefs {
    final manager = $$WallpaperHistoryTableTableManager(
            $_db, $_db.wallpaperHistory)
        .filter((f) =>
            f.contentId.contentId.sqlEquals($_itemColumn<int>('content_id')!));

    final cache =
        $_typedResult.readTableOrNull(_wallpaperHistoryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
      _favoritesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.favorites,
              aliasName: $_aliasNameGenerator(
                  db.artworks.contentId, db.favorites.contentId));

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager($_db, $_db.favorites).filter(
        (f) =>
            f.contentId.contentId.sqlEquals($_itemColumn<int>('content_id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ArtworksTableFilterComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get contentId => $composableBuilder(
      column: $table.contentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistUrl => $composableBuilder(
      column: $table.artistUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completitionYear => $composableBuilder(
      column: $table.completitionYear,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnFilters(column));

  Expression<bool> wallpaperHistoryRefs(
      Expression<bool> Function($$WallpaperHistoryTableFilterComposer f) f) {
    final $$WallpaperHistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.wallpaperHistory,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WallpaperHistoryTableFilterComposer(
              $db: $db,
              $table: $db.wallpaperHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> favoritesRefs(
      Expression<bool> Function($$FavoritesTableFilterComposer f) f) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.favorites,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FavoritesTableFilterComposer(
              $db: $db,
              $table: $db.favorites,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ArtworksTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get contentId => $composableBuilder(
      column: $table.contentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistUrl => $composableBuilder(
      column: $table.artistUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completitionYear => $composableBuilder(
      column: $table.completitionYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnOrderings(column));
}

class $$ArtworksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => column);

  GeneratedColumn<String> get artistUrl =>
      $composableBuilder(column: $table.artistUrl, builder: (column) => column);

  GeneratedColumn<int> get completitionYear => $composableBuilder(
      column: $table.completitionYear, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  Expression<T> wallpaperHistoryRefs<T extends Object>(
      Expression<T> Function($$WallpaperHistoryTableAnnotationComposer a) f) {
    final $$WallpaperHistoryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.wallpaperHistory,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WallpaperHistoryTableAnnotationComposer(
              $db: $db,
              $table: $db.wallpaperHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
      Expression<T> Function($$FavoritesTableAnnotationComposer a) f) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.favorites,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FavoritesTableAnnotationComposer(
              $db: $db,
              $table: $db.favorites,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ArtworksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ArtworksTable,
    Artwork,
    $$ArtworksTableFilterComposer,
    $$ArtworksTableOrderingComposer,
    $$ArtworksTableAnnotationComposer,
    $$ArtworksTableCreateCompanionBuilder,
    $$ArtworksTableUpdateCompanionBuilder,
    (Artwork, $$ArtworksTableReferences),
    Artwork,
    PrefetchHooks Function({bool wallpaperHistoryRefs, bool favoritesRefs})> {
  $$ArtworksTableTableManager(_$AppDatabase db, $ArtworksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> contentId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> artistName = const Value.absent(),
            Value<String?> artistUrl = const Value.absent(),
            Value<int?> completitionYear = const Value.absent(),
            Value<String> imageUrl = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<String?> style = const Value.absent(),
          }) =>
              ArtworksCompanion(
            contentId: contentId,
            title: title,
            artistName: artistName,
            artistUrl: artistUrl,
            completitionYear: completitionYear,
            imageUrl: imageUrl,
            localPath: localPath,
            width: width,
            height: height,
            genre: genre,
            style: style,
          ),
          createCompanionCallback: ({
            Value<int> contentId = const Value.absent(),
            required String title,
            required String artistName,
            Value<String?> artistUrl = const Value.absent(),
            Value<int?> completitionYear = const Value.absent(),
            required String imageUrl,
            Value<String?> localPath = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<String?> style = const Value.absent(),
          }) =>
              ArtworksCompanion.insert(
            contentId: contentId,
            title: title,
            artistName: artistName,
            artistUrl: artistUrl,
            completitionYear: completitionYear,
            imageUrl: imageUrl,
            localPath: localPath,
            width: width,
            height: height,
            genre: genre,
            style: style,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ArtworksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {wallpaperHistoryRefs = false, favoritesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (wallpaperHistoryRefs) db.wallpaperHistory,
                if (favoritesRefs) db.favorites
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wallpaperHistoryRefs)
                    await $_getPrefetchedData<Artwork, $ArtworksTable,
                            WallpaperHistoryData>(
                        currentTable: table,
                        referencedTable: $$ArtworksTableReferences
                            ._wallpaperHistoryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ArtworksTableReferences(db, table, p0)
                                .wallpaperHistoryRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contentId == item.contentId),
                        typedResults: items),
                  if (favoritesRefs)
                    await $_getPrefetchedData<Artwork, $ArtworksTable,
                            Favorite>(
                        currentTable: table,
                        referencedTable:
                            $$ArtworksTableReferences._favoritesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ArtworksTableReferences(db, table, p0)
                                .favoritesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contentId == item.contentId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ArtworksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ArtworksTable,
    Artwork,
    $$ArtworksTableFilterComposer,
    $$ArtworksTableOrderingComposer,
    $$ArtworksTableAnnotationComposer,
    $$ArtworksTableCreateCompanionBuilder,
    $$ArtworksTableUpdateCompanionBuilder,
    (Artwork, $$ArtworksTableReferences),
    Artwork,
    PrefetchHooks Function({bool wallpaperHistoryRefs, bool favoritesRefs})>;
typedef $$WallpaperHistoryTableCreateCompanionBuilder
    = WallpaperHistoryCompanion Function({
  Value<int> id,
  required int contentId,
  Value<DateTime> setAt,
});
typedef $$WallpaperHistoryTableUpdateCompanionBuilder
    = WallpaperHistoryCompanion Function({
  Value<int> id,
  Value<int> contentId,
  Value<DateTime> setAt,
});

final class $$WallpaperHistoryTableReferences extends BaseReferences<
    _$AppDatabase, $WallpaperHistoryTable, WallpaperHistoryData> {
  $$WallpaperHistoryTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ArtworksTable _contentIdTable(_$AppDatabase db) =>
      db.artworks.createAlias($_aliasNameGenerator(
          db.wallpaperHistory.contentId, db.artworks.contentId));

  $$ArtworksTableProcessedTableManager get contentId {
    final $_column = $_itemColumn<int>('content_id')!;

    final manager = $$ArtworksTableTableManager($_db, $_db.artworks)
        .filter((f) => f.contentId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WallpaperHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $WallpaperHistoryTable> {
  $$WallpaperHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get setAt => $composableBuilder(
      column: $table.setAt, builder: (column) => ColumnFilters(column));

  $$ArtworksTableFilterComposer get contentId {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableFilterComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WallpaperHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $WallpaperHistoryTable> {
  $$WallpaperHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get setAt => $composableBuilder(
      column: $table.setAt, builder: (column) => ColumnOrderings(column));

  $$ArtworksTableOrderingComposer get contentId {
    final $$ArtworksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableOrderingComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WallpaperHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WallpaperHistoryTable> {
  $$WallpaperHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get setAt =>
      $composableBuilder(column: $table.setAt, builder: (column) => column);

  $$ArtworksTableAnnotationComposer get contentId {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableAnnotationComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WallpaperHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WallpaperHistoryTable,
    WallpaperHistoryData,
    $$WallpaperHistoryTableFilterComposer,
    $$WallpaperHistoryTableOrderingComposer,
    $$WallpaperHistoryTableAnnotationComposer,
    $$WallpaperHistoryTableCreateCompanionBuilder,
    $$WallpaperHistoryTableUpdateCompanionBuilder,
    (WallpaperHistoryData, $$WallpaperHistoryTableReferences),
    WallpaperHistoryData,
    PrefetchHooks Function({bool contentId})> {
  $$WallpaperHistoryTableTableManager(
      _$AppDatabase db, $WallpaperHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WallpaperHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WallpaperHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WallpaperHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> contentId = const Value.absent(),
            Value<DateTime> setAt = const Value.absent(),
          }) =>
              WallpaperHistoryCompanion(
            id: id,
            contentId: contentId,
            setAt: setAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int contentId,
            Value<DateTime> setAt = const Value.absent(),
          }) =>
              WallpaperHistoryCompanion.insert(
            id: id,
            contentId: contentId,
            setAt: setAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WallpaperHistoryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({contentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (contentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contentId,
                    referencedTable:
                        $$WallpaperHistoryTableReferences._contentIdTable(db),
                    referencedColumn: $$WallpaperHistoryTableReferences
                        ._contentIdTable(db)
                        .contentId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WallpaperHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WallpaperHistoryTable,
    WallpaperHistoryData,
    $$WallpaperHistoryTableFilterComposer,
    $$WallpaperHistoryTableOrderingComposer,
    $$WallpaperHistoryTableAnnotationComposer,
    $$WallpaperHistoryTableCreateCompanionBuilder,
    $$WallpaperHistoryTableUpdateCompanionBuilder,
    (WallpaperHistoryData, $$WallpaperHistoryTableReferences),
    WallpaperHistoryData,
    PrefetchHooks Function({bool contentId})>;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  required int contentId,
  Value<DateTime> addedAt,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  Value<int> contentId,
  Value<DateTime> addedAt,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArtworksTable _contentIdTable(_$AppDatabase db) =>
      db.artworks.createAlias(
          $_aliasNameGenerator(db.favorites.contentId, db.artworks.contentId));

  $$ArtworksTableProcessedTableManager get contentId {
    final $_column = $_itemColumn<int>('content_id')!;

    final manager = $$ArtworksTableTableManager($_db, $_db.artworks)
        .filter((f) => f.contentId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$ArtworksTableFilterComposer get contentId {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableFilterComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$ArtworksTableOrderingComposer get contentId {
    final $$ArtworksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableOrderingComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$ArtworksTableAnnotationComposer get contentId {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contentId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.contentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableAnnotationComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, $$FavoritesTableReferences),
    Favorite,
    PrefetchHooks Function({bool contentId})> {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> contentId = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) =>
              FavoritesCompanion(
            id: id,
            contentId: contentId,
            addedAt: addedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int contentId,
            Value<DateTime> addedAt = const Value.absent(),
          }) =>
              FavoritesCompanion.insert(
            id: id,
            contentId: contentId,
            addedAt: addedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FavoritesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({contentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (contentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contentId,
                    referencedTable:
                        $$FavoritesTableReferences._contentIdTable(db),
                    referencedColumn: $$FavoritesTableReferences
                        ._contentIdTable(db)
                        .contentId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, $$FavoritesTableReferences),
    Favorite,
    PrefetchHooks Function({bool contentId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArtworksTableTableManager get artworks =>
      $$ArtworksTableTableManager(_db, _db.artworks);
  $$WallpaperHistoryTableTableManager get wallpaperHistory =>
      $$WallpaperHistoryTableTableManager(_db, _db.wallpaperHistory);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
}
