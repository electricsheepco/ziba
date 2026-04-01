import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/models/artwork.dart';

void main() {
  group('resolution filter', () {
    Artwork _artwork({int? width, int? height}) => Artwork(
          contentId: 1,
          title: 'Test',
          artistName: 'Artist',
          image: 'https://example.com/img.jpg',
          width: width,
          height: height,
        );

    test('landscape artwork ≥1920px wide passes', () {
      final a = _artwork(width: 2560, height: 1600);
      expect(_meetsResolution(a), isTrue);
    });

    test('portrait artwork ≥1920px tall passes', () {
      final a = _artwork(width: 1200, height: 2000);
      expect(_meetsResolution(a), isTrue);
    });

    test('small artwork fails', () {
      final a = _artwork(width: 800, height: 600);
      expect(_meetsResolution(a), isFalse);
    });

    test('null dimensions fail', () {
      final a = _artwork(width: null, height: null);
      expect(_meetsResolution(a), isFalse);
    });

    test('exactly 1920px passes', () {
      final a = _artwork(width: 1920, height: 1080);
      expect(_meetsResolution(a), isTrue);
    });
  });

  group('artist recency exclusion', () {
    test('excludes last 10, allows 11th', () {
      final recent = List.generate(10, (i) => 'artist-$i');
      expect(_shouldExcludeArtist('artist-0', recent), isTrue);
      expect(_shouldExcludeArtist('artist-9', recent), isTrue);
      expect(_shouldExcludeArtist('artist-10', recent), isFalse);
    });

    test('empty recent list excludes nothing', () {
      expect(_shouldExcludeArtist('any-artist', []), isFalse);
    });
  });
}

// Mirror the logic from WikiArtService (pure functions, no class dependency).
bool _meetsResolution(Artwork a) {
  if (a.width == null || a.height == null) return false;
  return [a.width!, a.height!].reduce((m, v) => m > v ? m : v) >= 1920;
}

bool _shouldExcludeArtist(String url, List<String> recent) {
  return recent.contains(url);
}
