import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'playlist_detail_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const PlaylistScreen({Key? key, required this.playlistService})
      : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Future<List<Playlist>> _playlistsFuture;
  List<Playlist> _playlists = [];
  bool _editMode = false;
  final Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await widget.playlistService.getPlaylists();
    setState(() {
      _playlists = playlists;
      _playlistsFuture = Future.value(playlists);
      _selectedIndexes.clear();
      _editMode = false;
    });
  }

  Future<void> _addPlaylist() async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 플레이리스트'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '플레이리스트 이름'),
          autofocus: true,
        ),
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
    if (confirmed == true && nameController.text.isNotEmpty) {
      final newPlaylist = Playlist(name: nameController.text);
      await widget.playlistService.savePlaylist(newPlaylist);
      await _loadPlaylists();
    }
  }

  Future<void> _removeSelectedPlaylists() async {
    final indexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in indexes) {
      final playlist = _playlists[idx];
      await widget.playlistService.deletePlaylist(playlist.name);
    }
    await _loadPlaylists();
  }

  Future<void> _reorderPlaylist(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    setState(() {
      final playlist = _playlists.removeAt(oldIndex);
      _playlists.insert(newIndex, playlist);
    });
    for (final p in _playlists) {
      await widget.playlistService.savePlaylist(p);
    }
    await _loadPlaylists();
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
      _selectedIndexes.clear();
    });
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플레이리스트'),
        actions: [
          if (_editMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '선택 삭제',
              onPressed: _selectedIndexes.isEmpty
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('플레이리스트 삭제'),
                          content: Text(
                              '선택한 ${_selectedIndexes.length}개의 플레이리스트를 삭제하시겠습니까?'),
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
                        await _removeSelectedPlaylists();
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '완료',
              onPressed: _toggleEditMode,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '플레이리스트 추가',
              onPressed: _addPlaylist,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '편집',
              onPressed: _toggleEditMode,
            ),
          ],
        ],
      ),
      body: _playlists.isEmpty
          ? const Center(child: Text('플레이리스트가 없습니다'))
          : ReorderableListView.builder(
              itemCount: _playlists.length,
              onReorder: _editMode ? _reorderPlaylist : (a, b) {},
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                final selected = _selectedIndexes.contains(index);
                return ListTile(
                  key: ValueKey(playlist.name),
                  leading: _editMode
                      ? Checkbox(
                          value: selected,
                          onChanged: (_) => _toggleSelect(index),
                        )
                      : Builder(
                          builder: (context) {
                            final covers = playlist.songs
                                .where((s) => s.albumArt != null)
                                .take(1)
                                .toList();
                            if (covers.isEmpty) {
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.playlist_play,
                                    color: Colors.white38),
                              );
                            } else {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(covers[0].albumArt!,
                                    width: 48, height: 48, fit: BoxFit.cover),
                              );
                            }
                          },
                        ),
                  title: Text(playlist.name),
                  subtitle: Text(() {
                    final totalSeconds = playlist.songs
                        .fold<int>(0, (sum, s) => sum + (s.duration ?? 0));
                    final songCount = playlist.songs.length;
                    if (songCount == 0) return '0곡';
                    if (totalSeconds == 0) return '$songCount곡';
                    return '$songCount곡 · ${_formatDuration(totalSeconds)}';
                  }()),
                  trailing: _editMode
                      ? ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child:
                                Icon(Icons.drag_handle, color: Colors.white38),
                          ),
                        )
                      : (() {
                          final bpms = playlist.songs
                              .where((s) => s.bpm != null)
                              .map((s) => s.bpm!)
                              .toList();
                          if (bpms.isEmpty) return null;
                          final minBpm = bpms.reduce((a, b) => a < b ? a : b);
                          final maxBpm = bpms.reduce((a, b) => a > b ? a : b);
                          if (minBpm == maxBpm) {
                            return Text('BPM $minBpm',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70));
                          } else {
                            return Text('BPM $minBpm~$maxBpm',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70));
                          }
                        })(),
                  onTap: _editMode
                      ? () => _toggleSelect(index)
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlist: playlist,
                                playlistService: widget.playlistService,
                              ),
                            ),
                          );
                          await _loadPlaylists();
                        },
                );
              },
            ),
    );
  }
}
