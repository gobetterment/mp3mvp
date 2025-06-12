import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';
import '../services/metadata_service.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SongListScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const SongListScreen({
    super.key,
    required this.playlistService,
  });

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final MetadataService _metadataService = MetadataService();
  List<Song> _songs = [];
  bool _isLoading = false;

  Future<void> _selectDirectory() async {
    try {
      setState(() => _isLoading = true);

      // Documents 폴더 경로 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      print('Music 폴더 경로: ${musicDir.path}');

      // MP3 파일 목록 가져오기
      final songs = await _metadataService.getSongsFromDirectory(musicDir.path);
      print('찾은 MP3 파일 수: ${songs.length}');

      setState(() {
        _songs = songs;
      });
    } catch (e) {
      print('에러 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addToPlaylist(Song song) async {
    final playlists = await widget.playlistService.getPlaylists();

    if (playlists.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('플레이리스트 없음'),
          content: const Text('새 플레이리스트를 만들겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('생성'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistsScreen(
                playlistService: widget.playlistService,
              ),
            ),
          );
        }
      }
      return;
    }

    final selectedPlaylist = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length}곡'),
                onTap: () => Navigator.pop(context, playlist.name),
              );
            },
          ),
        ),
      ),
    );

    if (selectedPlaylist != null) {
      await widget.playlistService.addSongToPlaylist(selectedPlaylist, song);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플레이리스트에 추가되었습니다')),
        );
      }
    }
  }

  Widget buildSongLeading(Song song) {
    if (song.albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          song.albumArt!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.music_note,
          color: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MP3 Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _isLoading ? null : _selectDirectory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '폴더를 선택하여 음악을 불러오세요',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _selectDirectory,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('폴더 선택'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: buildSongLeading(song),
                        title: Text(
                          song.title ?? 'Unknown Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(song.artist ?? 'Unknown Artist'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (song.bpm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${song.bpm} BPM',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.playlist_add),
                              onPressed: () => _addToPlaylist(song),
                            ),
                            const Icon(Icons.play_arrow),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                songs: _songs,
                                currentIndex: index,
                                playlistService: widget.playlistService,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
