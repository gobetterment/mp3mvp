import 'package:flutter_test/flutter_test.dart';
import 'package:bmpplayer/models/song.dart';

void main() {
  group('Song Model Tests', () {
    test('should create Song with all properties', () {
      final song = Song(
        filePath: '/path/to/song.mp3',
        artist: 'Test Artist',
        title: 'Test Title',
        bpm: 120,
        year: 2024,
        genre: 'Test Genre',
      );

      expect(song.filePath, equals('/path/to/song.mp3'));
      expect(song.artist, equals('Test Artist'));
      expect(song.title, equals('Test Title'));
      expect(song.bpm, equals(120));
      expect(song.year, equals(2024));
      expect(song.genre, equals('Test Genre'));
    });

    test('should create Song with only required properties', () {
      final song = Song(filePath: '/path/to/song.mp3');

      expect(song.filePath, equals('/path/to/song.mp3'));
      expect(song.artist, isNull);
      expect(song.title, isNull);
      expect(song.bpm, isNull);
      expect(song.year, isNull);
      expect(song.genre, isNull);
    });

    test('should convert Song to and from JSON', () {
      final originalSong = Song(
        filePath: '/path/to/song.mp3',
        artist: 'Test Artist',
        title: 'Test Title',
        bpm: 120,
        year: 2024,
        genre: 'Test Genre',
      );

      final json = originalSong.toJson();
      final restoredSong = Song.fromJson(json);

      expect(restoredSong.filePath, equals(originalSong.filePath));
      expect(restoredSong.artist, equals(originalSong.artist));
      expect(restoredSong.title, equals(originalSong.title));
      expect(restoredSong.bpm, equals(originalSong.bpm));
      expect(restoredSong.year, equals(originalSong.year));
      expect(restoredSong.genre, equals(originalSong.genre));
    });
  });
}
