import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../services/metadata_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/bpm_filter_bar.dart';
import '../widgets/song_list_tile.dart';
import '../providers/playlist_provider.dart';
import '../providers/like_provider.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  void _editPlaylist(BuildContext context) async {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 정보 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
              ),
            ],
          ),
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
      final updated = playlist.copyWith(
        name: nameController.text,
        description: descriptionController.text.trim(),
      );
      await Provider.of<PlaylistProvider>(context, listen: false)
          .addPlaylist(updated);
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
      // PlaylistProvider에 deletePlaylist 메서드가 필요하다면 추가
      // await Provider.of<PlaylistProvider>(context, listen: false).deletePlaylist(playlist.name);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final currentPlaylist =
        playlistProvider.getPlaylistByName(playlist.name) ?? playlist;
    final minMaxBpm = () {
      final bpms = currentPlaylist.songs
          .where((s) => s.bpm != null)
          .map((s) => s.bpm!)
          .toList();
      if (bpms.isEmpty) return null;
      final minBpm = bpms.reduce((a, b) => a < b ? a : b);
      final maxBpm = bpms.reduce((a, b) => a > b ? a : b);
      return minBpm == maxBpm ? 'BPM $minBpm' : 'BPM $minBpm~$maxBpm';
    }();
    final totalSeconds =
        currentPlaylist.songs.fold<int>(0, (sum, s) => sum + (s.duration ?? 0));
    final songCount = currentPlaylist.songs.length;
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
        title: Text(currentPlaylist.name),
        actions: currentPlaylist.name == '❤️ Liked Songs'
            ? []
            : [
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 커버 이미지 (1~4장)
                Builder(
                  builder: (context) {
                    final covers = currentPlaylist.songs
                        .where((s) => s.albumArt != null)
                        .take(4)
                        .toList();
                    if (covers.isEmpty) {
                      return Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.music_note,
                            size: 48, color: Colors.white38),
                      );
                    } else if (covers.length == 1) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(covers[0].albumArt!,
                            width: 96, height: 96, fit: BoxFit.cover),
                      );
                    } else {
                      return SizedBox(
                        width: 96,
                        height: 96,
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: covers
                              .map((s) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(s.albumArt!,
                                        fit: BoxFit.cover),
                                  ))
                              .toList(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentPlaylist.description != null &&
                          currentPlaylist.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            currentPlaylist.description!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (currentPlaylist.name != '❤️ Liked Songs')
                        Text(
                          '생성: ${currentPlaylist.createdAt.toLocal().toString().split(" ")[0]} / 수정: ${currentPlaylist.updatedAt.toLocal().toString().split(" ")[0]}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white54),
                        ),
                      if (minMaxBpm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(minMaxBpm,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            '$songCount곡 · ${formatDuration(totalSeconds)}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: songCount == 0
                                ? null
                                : () {
                                    final audioProvider =
                                        Provider.of<AudioProvider>(context,
                                            listen: false);
                                    audioProvider.playSong(
                                        currentPlaylist.songs, 0);
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('재생'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: songCount == 0
                                ? null
                                : () {
                                    final audioProvider =
                                        Provider.of<AudioProvider>(context,
                                            listen: false);
                                    final shuffled =
                                        List<Song>.from(currentPlaylist.songs)
                                          ..shuffle();
                                    audioProvider.playSong(shuffled, 0);
                                  },
                            icon: const Icon(Icons.shuffle),
                            label: const Text('임의재생'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 구분선 제거, 아래에 곡 리스트와의 간격만 추가
          const SizedBox(height: 10),
          Expanded(
            child: _PlaylistSongList(
              playlist: currentPlaylist,
              showAddSong: currentPlaylist.name != '❤️ Liked Songs',
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistSongList extends StatelessWidget {
  final Playlist playlist;
  final bool showAddSong;
  const _PlaylistSongList({required this.playlist, this.showAddSong = true});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final currentPlaylist =
        playlistProvider.getPlaylistByName(playlist.name) ?? playlist;
    final songs = currentPlaylist.songs;
    if (currentPlaylist.name == '❤️ Liked Songs') {
      return Consumer<LikeProvider>(
        builder: (context, likeProvider, _) {
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final likeCount = likeProvider.getLikeCount(song.filePath);
              return SongListTile(
                song: song,
                showBpm: true,
                onTap: () {
                  final audioProvider =
                      Provider.of<AudioProvider>(context, listen: false);
                  audioProvider.playSong(songs, index);
                },
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$likeCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return ReorderableListView.builder(
      itemCount: showAddSong ? songs.length + 1 : songs.length,
      onReorder: (oldIndex, newIndex) async {
        if (oldIndex < newIndex) newIndex--;
        await Provider.of<PlaylistProvider>(context, listen: false)
            .reorderSongsInPlaylist(playlist.name, oldIndex, newIndex);
      },
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        if (showAddSong && (songs.isEmpty || index == songs.length)) {
          return ListTile(
            key: const ValueKey('add_song'),
            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
            title: const Text('노래 추가',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () async {
              final added = await showModalBottomSheet<List<Song>>(
                context: context,
                isScrollControlled: true,
                builder: (context) => SongMultiSelectScreen(
                  alreadyInPlaylist: songs,
                ),
              );
              if (added != null && added.isNotEmpty) {
                for (final song in added) {
                  await Provider.of<PlaylistProvider>(context, listen: false)
                      .addSongToPlaylist(playlist.name, song);
                }
              }
            },
          );
        }
        final song = songs[index];
        return Dismissible(
          key: ValueKey(song.filePath),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await Provider.of<PlaylistProvider>(context, listen: false)
                .removeSongFromPlaylist(playlist.name, song);
          },
          child: SongListTile(
            song: song,
            showBpm: true,
            onTap: () {
              final audioProvider =
                  Provider.of<AudioProvider>(context, listen: false);
              audioProvider.playSong(songs, index);
            },
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: Colors.white38),
            ),
          ),
        );
      },
    );
  }
}

class SongMultiSelectScreen extends StatefulWidget {
  final List<Song> alreadyInPlaylist;
  const SongMultiSelectScreen({super.key, required this.alreadyInPlaylist});

  @override
  State<SongMultiSelectScreen> createState() => _SongMultiSelectScreenState();
}

class _SongMultiSelectScreenState extends State<SongMultiSelectScreen> {
  final MetadataService _metadataService = MetadataService();
  List<Song> _songs = [];
  final Set<String> _selected = {};
  bool _isLoading = false;
  RangeValues _bpmFilterRange = const RangeValues(0, 250);

  // 검색 기능 추가
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 검색어에 따른 곡 필터링 함수
  List<Song> _filterSongsBySearch(List<Song> songs) {
    if (_searchQuery.isEmpty) return songs;

    final query = _searchQuery.toLowerCase();
    return songs.where((song) {
      return (song.title?.toLowerCase().contains(query) ?? false) ||
          (song.artist?.toLowerCase().contains(query) ?? false) ||
          (song.album?.toLowerCase().contains(query) ?? false) ||
          (song.genre?.toLowerCase().contains(query) ?? false) ||
          (song.year?.toString().contains(query) ?? false);
    }).toList();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    // 홈과 동일하게 전체 음악 디렉토리 사용
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${dir.path}/music');
    // print('Loading songs from directory: ${musicDir.path}');

    if (!await musicDir.exists()) {
      // print('Music directory does not exist, creating...');
      await musicDir.create(recursive: true);
    }

    final songs = await _metadataService.getSongsFromDirectory(musicDir.path);
    // print('Found ${songs.length} songs in directory');

    setState(() {
      _songs = songs
          .where((s) =>
              !widget.alreadyInPlaylist.any((p) => p.filePath == s.filePath))
          .toList();
      // print(
      //     'Filtered to ${_songs.length} songs (excluding already in playlist)');
      _isLoading = false;
    });
  }

  List<Song> get _filteredSongs {
    final bpmFilteredSongs = _songs.where((song) {
      final bpm = song.bpm ?? 0;
      return bpm >= _bpmFilterRange.start && bpm <= _bpmFilterRange.end;
    }).toList();

    // 검색 필터링 추가
    return _filterSongsBySearch(bpmFilteredSongs);
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
                    // 검색창 추가
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '곡, 아티스트, 앨범, 장르, 연도로 검색...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BpmFilterBar(
                            min: 0,
                            max: 250,
                            divisions: 250,
                            values: _bpmFilterRange,
                            onChanged: (v) =>
                                setState(() => _bpmFilterRange = v),
                            labelPrefix: 'BPM',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredSongs.isEmpty && _searchQuery.isNotEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '검색 결과가 없습니다',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '다른 검색어를 입력해보세요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredSongs.length,
                              itemBuilder: (context, index) {
                                final song = _filteredSongs[index];
                                return SongListTile(
                                  song: song,
                                  showBpm: true,
                                  showCheckbox: true,
                                  checked: _selected.contains(song.filePath),
                                  onCheckedChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selected.add(song.filePath);
                                      } else {
                                        _selected.remove(song.filePath);
                                      }
                                    });
                                  },
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
