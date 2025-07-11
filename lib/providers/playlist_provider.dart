import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import 'like_provider.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService;
  List<Playlist> _playlists = [];
  bool _isLoaded = false;
  LikeProvider? _likeProvider;
  VoidCallback? _likeListener;
  List<Song> _allSongs = [];

  PlaylistProvider(this._playlistService);

  void setLikeProvider(LikeProvider likeProvider) {
    if (_likeProvider == likeProvider) return;
    if (_likeProvider != null && _likeListener != null) {
      _likeProvider!.removeListener(_likeListener!);
    }
    _likeProvider = likeProvider;
    _likeListener = () {
      notifyListeners();
    };
    _likeProvider?.addListener(_likeListener!);
  }

  void setAllSongs(List<Song> songs) {
    _allSongs = songs;
    notifyListeners();
  }

  List<Playlist> get playlists {
    if (_likeProvider == null) return _playlists;

    // 항상 좋아요 플레이리스트를 최상단에 고정
    final likedSongPaths = _likeProvider!.likedSongPaths;
    final likedSongsMap = <String, Song>{};
    for (final path in likedSongPaths) {
      final found = _allSongs.where((s) => s.filePath == path);
      for (final song in found) {
        likedSongsMap[song.filePath] = song;
      }
    }
    final likedSongs = likedSongsMap.values.toList();
    // 좋아요 카운트 높은 순으로 정렬
    if (_likeProvider != null) {
      likedSongs.sort((a, b) => _likeProvider!
          .getLikeCount(b.filePath)
          .compareTo(_likeProvider!.getLikeCount(a.filePath)));
    }
    // 기존에 있던 좋아요 플레이리스트 제거
    _playlists.removeWhere((p) => p.name == '❤️ Liked Songs');
    // 항상 최상단에 추가 (곡이 없으면 빈 리스트)
    _playlists.insert(0, Playlist(name: '❤️ Liked Songs', songs: likedSongs));
    return _playlists;
  }

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

    // 좋아요 플레이리스트에서 곡을 제거할 때는 좋아요 정보도 함께 삭제
    if (playlistName == '❤️ Liked Songs' && _likeProvider != null) {
      _likeProvider!.removeSong(song.filePath);
    }

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
