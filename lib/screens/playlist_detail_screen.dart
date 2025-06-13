import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../services/metadata_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  final PlaylistService playlistService;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlist,
    required this.playlistService,
  }) : super(key: key);

  void _editPlaylist(BuildContext context) async {
    final nameController = TextEditingController(text: playlist.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 이름 변경'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (confirmed == true && nameController.text.isNotEmpty) {
      final updated = playlist.copyWith(name: nameController.text);
      await playlistService.savePlaylist(updated);
      Navigator.pop(context, updated);
    }
  }

  void _deletePlaylist(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
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
      await playlistService.deletePlaylist(playlist.name);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minMaxBpm = () {
      final bpms = playlist.songs
          .where((s) => s.bpm != null)
          .map((s) => s.bpm!)
          .toList();
      if (bpms.isEmpty) return null;
      final minBpm = bpms.reduce((a, b) => a < b ? a : b);
      final maxBpm = bpms.reduce((a, b) => a > b ? a : b);
      return minBpm == maxBpm ? 'BPM $minBpm' : 'BPM $minBpm~$maxBpm';
    }();
    final totalSeconds =
        playlist.songs.fold<int>(0, (sum, s) => sum + (s.duration ?? 0));
    final songCount = playlist.songs.length;
    String formatDuration(int totalSeconds) {
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      if (hours > 0) {
        return '$hours시간 $minutes분';
      } else {
        return '$minutes분';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '이름 변경',
            onPressed: () => _editPlaylist(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '삭제',
            onPressed: () => _deletePlaylist(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '생성: ${playlist.createdAt.toLocal().toString().split(" ")[0]} / 수정: ${playlist.updatedAt.toLocal().toString().split(" ")[0]}',
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
                if (minMaxBpm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(minMaxBpm,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('$songCount곡 · ${formatDuration(totalSeconds)}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: songCount == 0
                          ? null
                          : () {
                              final audioProvider = Provider.of<AudioProvider>(
                                  context,
                                  listen: false);
                              audioProvider.playSong(playlist.songs, 0);
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('재생'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: songCount == 0
                          ? null
                          : () {
                              final audioProvider = Provider.of<AudioProvider>(
                                  context,
                                  listen: false);
                              final shuffled = List<Song>.from(playlist.songs)
                                ..shuffle();
                              audioProvider.playSong(shuffled, 0);
                            },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('임의재생'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _PlaylistSongList(
              playlist: playlist,
              playlistService: playlistService,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistSongList extends StatefulWidget {
  final Playlist playlist;
  final PlaylistService playlistService;
  const _PlaylistSongList(
      {required this.playlist, required this.playlistService});

  @override
  State<_PlaylistSongList> createState() => _PlaylistSongListState();
}

class _PlaylistSongListState extends State<_PlaylistSongList> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List<Song>.from(widget.playlist.songs);
  }

  Future<void> _removeSong(int index) async {
    final song = _songs[index];
    setState(() => _songs.removeAt(index));
    await widget.playlistService
        .removeSongFromPlaylist(widget.playlist.name, song);
  }

  Future<void> _reorderSong(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    setState(() {
      final song = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, song);
    });
    final updated = widget.playlist.copyWith(songs: _songs);
    await widget.playlistService.savePlaylist(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _songs.length + 1,
      itemBuilder: (context, index) {
        if (_songs.isEmpty || index == _songs.length) {
          // 노래 추가 항목 (맨 위 또는 맨 마지막)
          return ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
            title: const Text('노래 추가',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () async {
              final added = await showModalBottomSheet<List<Song>>(
                context: context,
                isScrollControlled: true,
                builder: (context) => SongMultiSelectScreen(
                  playlistService: widget.playlistService,
                  alreadyInPlaylist: _songs,
                ),
              );
              if (added != null && added.isNotEmpty) {
                for (final song in added) {
                  await widget.playlistService
                      .addSongToPlaylist(widget.playlist.name, song);
                }
                setState(() {
                  _songs.addAll(added);
                });
              }
            },
          );
        }
        final song = _songs[index];
        return Dismissible(
          key: ValueKey(song.filePath),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeSong(index),
          child: GestureDetector(
            onLongPress: () {},
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: song.albumArt != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        song.albumArt!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.black, size: 32),
                    ),
              title: Text(
                song.title ?? 'Unknown Title',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      song.artist,
                      if (song.year != null) song.year.toString(),
                    ].where((e) => e != null && e.isNotEmpty).join(' | '),
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (song.genre != null && song.genre!.isNotEmpty)
                    Text(
                      song.genre!,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (song.bpm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'BPM ${song.bpm}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.drag_handle, color: Colors.white38),
                    ),
                  ),
                ],
              ),
              onTap: () {
                final audioProvider =
                    Provider.of<AudioProvider>(context, listen: false);
                audioProvider.playSong(_songs, index);
              },
            ),
          ),
        );
      },
    );
  }
}

class SongMultiSelectScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final List<Song> alreadyInPlaylist;
  const SongMultiSelectScreen(
      {super.key,
      required this.playlistService,
      required this.alreadyInPlaylist});

  @override
  State<SongMultiSelectScreen> createState() => _SongMultiSelectScreenState();
}

class _SongMultiSelectScreenState extends State<SongMultiSelectScreen> {
  final MetadataService _metadataService = MetadataService();
  List<Song> _songs = [];
  final Set<String> _selected = {};
  bool _isLoading = false;
  RangeValues _bpmRange = const RangeValues(0, 300);

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/music');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    final songs = await _metadataService.getSongsFromDirectory(musicDir.path);
    setState(() {
      _songs = songs
          .where((s) =>
              !widget.alreadyInPlaylist.any((p) => p.filePath == s.filePath))
          .toList();
      _isLoading = false;
    });
  }

  List<Song> get _filteredSongs {
    return _songs.where((song) {
      final bpm = song.bpm ?? 0;
      return bpm >= _bpmRange.start && bpm <= _bpmRange.end;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Scaffold(
          appBar: AppBar(
            title: const Text('노래 선택'),
            actions: [
              TextButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        final selectedSongs = _songs
                            .where((s) => _selected.contains(s.filePath))
                            .toList();
                        Navigator.pop(context, selectedSongs);
                      },
                child: const Text('추가', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('BPM',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${_bpmRange.start.round()} - ${_bpmRange.end.round()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveTrackColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              thumbColor: Theme.of(context).colorScheme.primary,
                              overlayColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              valueIndicatorColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: RangeSlider(
                              min: 0,
                              max: 300,
                              divisions: 60,
                              values: _bpmRange,
                              onChanged: (v) => setState(() => _bpmRange = v),
                              labels: RangeLabels(
                                _bpmRange.start.round().toString(),
                                _bpmRange.end.round().toString(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, idx) {
                          final song = _filteredSongs[idx];
                          final checked = _selected.contains(song.filePath);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: checked,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selected.add(song.filePath);
                                      } else {
                                        _selected.remove(song.filePath);
                                      }
                                    });
                                  },
                                ),
                                song.albumArt != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(
                                          song.albumArt!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.music_note,
                                            color: Colors.black, size: 24),
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title ?? 'Unknown Title',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        [
                                          song.artist,
                                          if (song.year != null)
                                            song.year.toString(),
                                        ]
                                            .where((e) =>
                                                e != null && e.isNotEmpty)
                                            .join(' | '),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (song.genre != null &&
                                          song.genre!.isNotEmpty)
                                        Text(
                                          song.genre!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white54),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (song.bpm != null)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      'BPM ${song.bpm}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
