import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService;
  List<Playlist> _playlists = [];
  bool _isLoaded = false;

  PlaylistProvider(this._playlistService);

  List<Playlist> get playlists => _playlists;

  Future<void> loadPlaylists() async {
    _playlists = await _playlistService.getPlaylists();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addPlaylist(Playlist playlist) async {
    await _playlistService.savePlaylist(playlist);
    await loadPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistName, Song song) async {
    await _playlistService.addSongToPlaylist(playlistName, song);
    await loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(String playlistName, Song song) async {
    await _playlistService.removeSongFromPlaylist(playlistName, song);
    await loadPlaylists();
  }

  Playlist? getPlaylistByName(String name) {
    for (final p in _playlists) {
      if (p.name == name) return p;
    }
    return null;
  }

  bool get isLoaded => _isLoaded;

  Future<void> deletePlaylist(String playlistName) async {
    await _playlistService.deletePlaylist(playlistName);
    await loadPlaylists();
  }

  Future<void> reorderSongsInPlaylist(
      String playlistName, int oldIndex, int newIndex) async {
    final playlist = getPlaylistByName(playlistName);
    if (playlist == null) return;
    final songs = List<Song>.from(playlist.songs);
    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);
    final updated = playlist.copyWith(songs: songs);
    await _playlistService.savePlaylist(updated);
    await loadPlaylists();
  }
}
