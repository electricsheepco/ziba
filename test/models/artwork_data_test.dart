import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/models/artwork_data.dart';

void main() {
  test('ArtworkData holds all required fields', () {
    const data = ArtworkData(
      contentId: 42,
      title: 'The Starry Night',
      artistName: 'Vincent van Gogh',
      completitionYear: 1889,
      imageUrl: 'https://example.com/img.jpg',
      localPath: '/tmp/42.jpg',
      width: 921,
      height: 737,
    );

    expect(data.contentId, 42);
    expect(data.title, 'The Starry Night');
    expect(data.localPath, '/tmp/42.jpg');
    expect(data.width, 921);
  });

  test('localPath and dimensions are nullable', () {
    const data = ArtworkData(
      contentId: 1,
      title: 'Test',
      artistName: 'Artist',
      imageUrl: 'https://example.com/img.jpg',
    );

    expect(data.localPath, isNull);
    expect(data.width, isNull);
    expect(data.height, isNull);
    expect(data.completitionYear, isNull);
  });
}
