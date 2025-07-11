import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bmpplayer/models/playlist.dart';
import 'package:bmpplayer/models/song.dart';

class PlaylistService {
  static const String _playlistsKey = 'playlists';
  final SharedPreferences _prefs;

  PlaylistService(this._prefs);

  Future<List<Playlist>> getPlaylists() async {
    final String? playlistsJson = _prefs.getString(_playlistsKey);
    if (playlistsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(playlistsJson);
    return decoded.map((json) => Playlist.fromJson(json)).toList();
  }

  Future<void> savePlaylist(Playlist playlist) async {
    final playlists = await getPlaylists();
    final existingIndex = playlists.indexWhere((p) => p.name == playlist.name);

    final now = DateTime.now();
    final updated = playlist.copyWith(updatedAt: now);
    if (existingIndex >= 0) {
      playlists[existingIndex] = updated;
    } else {
      playlists.add(updated.copyWith(createdAt: now));
    }
    await _prefs.setString(_playlistsKey, jsonEncode(playlists));
  }

  Future<void> addSongToPlaylist(String playlistName, Song song) async {
    final playlists = await getPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p.name == playlistName);

    if (playlistIndex >= 0) {
      final playlist = playlists[playlistIndex];
      if (!playlist.songs.any((s) => s.filePath == song.filePath)) {
        final updatedSongs = List<Song>.from(playlist.songs)..add(song);
        playlists[playlistIndex] =
            playlist.copyWith(songs: updatedSongs, updatedAt: DateTime.now());
        await _prefs.setString(_playlistsKey, jsonEncode(playlists));
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistName, Song song) async {
    final playlists = await getPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p.name == playlistName);

    if (playlistIndex >= 0) {
      final playlist = playlists[playlistIndex];
      final updatedSongs =
          playlist.songs.where((s) => s.filePath != song.filePath).toList();
      playlists[playlistIndex] =
          playlist.copyWith(songs: updatedSongs, updatedAt: DateTime.now());
      await _prefs.setString(_playlistsKey, jsonEncode(playlists));
    }
  }

  Future<void> deletePlaylist(String playlistName) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.name == playlistName);
    await _prefs.setString(_playlistsKey, jsonEncode(playlists));
  }
}
