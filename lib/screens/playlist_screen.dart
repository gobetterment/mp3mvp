import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  final PlaylistService playlistService;

  const PlaylistScreen({
    super.key,
    required this.playlist,
    required this.playlistService,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Playlist _playlist;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  Future<void> _removeSong(Song song) async {
    await widget.playlistService.removeSongFromPlaylist(_playlist.name, song);
    setState(() {
      _playlist = _playlist.copyWith(
        songs:
            _playlist.songs.where((s) => s.filePath != song.filePath).toList(),
      );
    });
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
        title: Text(_playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('플레이리스트 삭제'),
                  content: Text('${_playlist.name} 플레이리스트를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await widget.playlistService.deletePlaylist(_playlist.name);
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: _playlist.songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '플레이리스트가 비어있습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _playlist.songs.length,
              itemBuilder: (context, index) {
                final song = _playlist.songs[index];
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
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeSong(song),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            songs: _playlist.songs,
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
