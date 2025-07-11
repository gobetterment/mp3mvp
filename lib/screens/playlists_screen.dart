import 'package:flutter/material.dart';
import '../models/playlist.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  bool _editMode = false;
  final Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaylistProvider>(context, listen: false).loadPlaylists();
    });
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

  Future<void> _removeSelectedPlaylists(
      BuildContext context, List<Playlist> playlists) async {
    final indexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    for (final idx in indexes) {
      final playlist = playlists[idx];
      await playlistProvider.deletePlaylist(playlist.name);
    }
    setState(() {
      _selectedIndexes.clear();
      _editMode = false;
    });
    await playlistProvider.loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final playlists = playlistProvider.playlists;
        return Scaffold(
          appBar: AppBar(
            title: const Text('플레이리스트'),
            actions: [
              if (_editMode)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: '선택 삭제',
                  onPressed: _selectedIndexes.isEmpty
                      ? null
                      : () async {
                          await _removeSelectedPlaylists(context, playlists);
                        },
                ),
              IconButton(
                icon: Icon(_editMode ? Icons.check : Icons.edit),
                tooltip: _editMode ? '완료' : '편집',
                onPressed: _toggleEditMode,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final nameController = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('새 플레이리스트'),
                      content: TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: '플레이리스트 이름'),
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
                    await Provider.of<PlaylistProvider>(context, listen: false)
                        .addPlaylist(newPlaylist);
                  }
                },
              ),
            ],
          ),
          body: playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_play,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      const Text('플레이리스트가 없습니다',
                          style:
                              TextStyle(fontSize: 18, color: Colors.white70)),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: playlists.length,
                  onReorder: _editMode
                      ? (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex--;
                            final playlist = playlists.removeAt(oldIndex);
                            playlists.insert(newIndex, playlist);
                          });
                        }
                      : (a, b) {},
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(top: 0, bottom: 32),
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final covers = playlist.songs
                        .where((s) => s.albumArt != null)
                        .take(4)
                        .toList();
                    final songCount = playlist.songs.length;
                    final totalSeconds = playlist.songs
                        .fold<int>(0, (sum, s) => sum + (s.duration ?? 0));
                    final bpms = playlist.songs
                        .where((s) => s.bpm != null)
                        .map((s) => s.bpm!)
                        .toList();
                    String bpmText = '';
                    if (bpms.isNotEmpty) {
                      final minBpm = bpms.reduce((a, b) => a < b ? a : b);
                      final maxBpm = bpms.reduce((a, b) => a > b ? a : b);
                      bpmText = minBpm == maxBpm
                          ? 'BPM $minBpm'
                          : 'BPM $minBpm~$maxBpm';
                    }
                    String formatDuration(int totalSeconds) {
                      final hours = totalSeconds ~/ 3600;
                      final minutes = (totalSeconds % 3600) ~/ 60;
                      if (hours > 0) {
                        return '$hours시간 $minutes분';
                      } else {
                        return '$minutes분';
                      }
                    }

                    final selected = _selectedIndexes.contains(index);
                    return Dismissible(
                      key: ValueKey(playlist.name),
                      direction: _editMode
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: _editMode
                          ? (_) async {
                              await Provider.of<PlaylistProvider>(context,
                                      listen: false)
                                  .deletePlaylist(playlist.name);
                            }
                          : null,
                      child: Column(
                        children: [
                          Container(
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.13)
                                : Colors.transparent,
                            padding: EdgeInsets.zero, // 바깥쪽 패딩 최소화
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _editMode
                                  ? () => _toggleSelect(index)
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PlaylistDetailScreen(
                                            playlist: playlist,
                                          ),
                                        ),
                                      );
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 7,
                                    horizontal: 6), // 터치 영역 내부 여백 넉넉히
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_editMode &&
                                        playlist.name != '❤️ 좋아요 곡')
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Checkbox(
                                          value: selected,
                                          onChanged: (_) =>
                                              _toggleSelect(index),
                                          activeColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    // 앨범커버
                                    Container(
                                      width: 56,
                                      height: 56,
                                      margin: const EdgeInsets.only(
                                          left: 16, right: 0),
                                      child: covers.isEmpty
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.18),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                  Icons.music_note,
                                                  color: Colors.white38,
                                                  size: 32),
                                            )
                                          : covers.length == 1
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.memory(
                                                      covers[0].albumArt!,
                                                      width: 56,
                                                      height: 56,
                                                      fit: BoxFit.cover),
                                                )
                                              : GridView.count(
                                                  crossAxisCount: 2,
                                                  mainAxisSpacing: 1,
                                                  crossAxisSpacing: 1,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  children: covers
                                                      .map((s) => ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            child: Image.memory(
                                                                s.albumArt!,
                                                                fit: BoxFit
                                                                    .cover),
                                                          ))
                                                      .toList(),
                                                ),
                                    ),
                                    const SizedBox(width: 14),
                                    // 정보(타이틀, 곡수/시간, 메모)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            playlist.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: selected
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            songCount > 0
                                                ? '$songCount곡 · ${formatDuration(totalSeconds)}'
                                                : '',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white70),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (playlist.description != null &&
                                              playlist.description!.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Text(
                                                playlist.description!,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white38),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          if (playlist.description == null ||
                                              playlist.description!.isEmpty)
                                            const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                    // BPM 텍스트 (세로 중앙)
                                    if (bpmText.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: SizedBox(
                                          height: 56,
                                          child: Center(
                                            child: Text(
                                              bpmText,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_editMode)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_handle,
                                              color: Colors.white38, size: 22),
                                        ),
                                      ),
                                    if (!_editMode)
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(left: 2, right: 8),
                                        child: Icon(Icons.chevron_right,
                                            color: Colors.white24, size: 22),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (index < playlists.length - 1)
                            const SizedBox(height: 8), // 리스트 간 간격
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
