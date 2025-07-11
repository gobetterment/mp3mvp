import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bmpplayer/services/playlist_service.dart';
import 'package:bmpplayer/models/playlist.dart';
import 'package:bmpplayer/models/song.dart';

void main() {
  late SharedPreferences prefs;
  late PlaylistService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = PlaylistService(prefs);
  });

  group('PlaylistService Tests', () {
    final testSong = Song(
      filePath: '/path/to/song.mp3',
      artist: 'Test Artist',
      title: 'Test Title',
    );

    test('should save and retrieve playlist', () async {
      final playlist = Playlist(
        name: 'Test Playlist',
        songs: [testSong],
      );

      await service.savePlaylist(playlist);
      final playlists = await service.getPlaylists();

      expect(playlists.length, equals(1));
      expect(playlists.first.name, equals('Test Playlist'));
      expect(playlists.first.songs.length, equals(1));
      expect(playlists.first.songs.first.filePath, equals(testSong.filePath));
    });

    test('should add song to existing playlist', () async {
      final playlist = Playlist(name: 'Test Playlist');
      await service.savePlaylist(playlist);

      final newSong = Song(filePath: '/path/to/another.mp3');
      await service.addSongToPlaylist('Test Playlist', newSong);

      final playlists = await service.getPlaylists();
      expect(playlists.first.songs.length, equals(1));
      expect(playlists.first.songs.first.filePath, equals(newSong.filePath));
    });

    test('should not add duplicate song to playlist', () async {
      final playlist = Playlist(
        name: 'Test Playlist',
        songs: [testSong],
      );
      await service.savePlaylist(playlist);

      await service.addSongToPlaylist('Test Playlist', testSong);

      final playlists = await service.getPlaylists();
      expect(playlists.first.songs.length, equals(1));
    });

    test('should remove song from playlist', () async {
      final playlist = Playlist(
        name: 'Test Playlist',
        songs: [testSong],
      );
      await service.savePlaylist(playlist);

      await service.removeSongFromPlaylist('Test Playlist', testSong);

      final playlists = await service.getPlaylists();
      expect(playlists.first.songs, isEmpty);
    });

    test('should delete playlist', () async {
      final playlist = Playlist(name: 'Test Playlist');
      await service.savePlaylist(playlist);

      await service.deletePlaylist('Test Playlist');

      final playlists = await service.getPlaylists();
      expect(playlists, isEmpty);
    });
  });
}
