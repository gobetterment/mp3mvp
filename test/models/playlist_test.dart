import 'package:flutter_test/flutter_test.dart';
import 'package:mp3_player/models/playlist.dart';
import 'package:mp3_player/models/song.dart';

void main() {
  group('Playlist Model Tests', () {
    final testSong = Song(
      filePath: '/path/to/song.mp3',
      artist: 'Test Artist',
      title: 'Test Title',
    );

    test('should create Playlist with name and songs', () {
      final playlist = Playlist(
        name: 'Test Playlist',
        songs: [testSong],
      );

      expect(playlist.name, equals('Test Playlist'));
      expect(playlist.songs.length, equals(1));
      expect(playlist.songs.first, equals(testSong));
    });

    test('should create Playlist with empty songs list', () {
      final playlist = Playlist(name: 'Test Playlist');

      expect(playlist.name, equals('Test Playlist'));
      expect(playlist.songs, isEmpty);
    });

    test('should convert Playlist to and from JSON', () {
      final originalPlaylist = Playlist(
        name: 'Test Playlist',
        songs: [testSong],
      );

      final json = originalPlaylist.toJson();
      final restoredPlaylist = Playlist.fromJson(json);

      expect(restoredPlaylist.name, equals(originalPlaylist.name));
      expect(
          restoredPlaylist.songs.length, equals(originalPlaylist.songs.length));
      expect(restoredPlaylist.songs.first.filePath, equals(testSong.filePath));
    });

    test('should create copy of Playlist with modified properties', () {
      final originalPlaylist = Playlist(
        name: 'Test Playlist',
        songs: [testSong],
      );

      final newSong = Song(filePath: '/path/to/another.mp3');
      final modifiedPlaylist = originalPlaylist.copyWith(
        name: 'Modified Playlist',
        songs: [newSong],
      );

      expect(modifiedPlaylist.name, equals('Modified Playlist'));
      expect(modifiedPlaylist.songs.length, equals(1));
      expect(modifiedPlaylist.songs.first.filePath,
          equals('/path/to/another.mp3'));
    });
  });
}
