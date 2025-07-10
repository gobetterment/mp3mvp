import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../widgets/song_list_tile.dart';
import 'playlists_screen.dart';

class PlayerScreen extends StatefulWidget {
  final List<Song> songs;
  final int currentIndex;
  final PlaylistService playlistService;
  final AudioPlayer audioPlayer;

  const PlayerScreen({
    super.key,
    required this.songs,
    required this.currentIndex,
    required this.playlistService,
    required this.audioPlayer,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late int _currentIndex;
  late Song _currentSong;
  late AudioPlayer _audioPlayer;
  final DraggableScrollableController draggableController =
      DraggableScrollableController();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffle = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _currentSong = widget.songs[_currentIndex];
    _audioPlayer = widget.audioPlayer;
    _initAudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
    _audioPlayer.positionStream.listen((pos) {
      setState(() {
        _position = pos;
      });
    });
    _audioPlayer.durationStream.listen((dur) {
      setState(() {
        _duration = dur ?? Duration.zero;
      });
    });
  }

  Future<void> _initAudioPlayer() async {
    setState(() => _isLoading = true);
    try {
      String? currentPath;
      final currentSource = _audioPlayer.audioSource;
      if (currentSource != null && currentSource is UriAudioSource) {
        currentPath = currentSource.uri.toFilePath();
      }
      if (currentPath != _currentSong.filePath) {
        await _audioPlayer.setFilePath(_currentSong.filePath);
        await _audioPlayer.play();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading audio: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentSong = widget.songs[_currentIndex];
      });
      _initAudioPlayer();
    }
  }

  void _playNext() {
    if (_currentIndex < widget.songs.length - 1) {
      setState(() {
        _currentIndex++;
        _currentSong = widget.songs[_currentIndex];
      });
      _initAudioPlayer();
    }
  }

  @override
  void dispose() {
    // _audioPlayer.dispose(); // 외부에서 관리하므로 dispose하지 않음
    super.dispose();
  }

  Future<void> _addToPlaylist() async {
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
      await widget.playlistService
          .addSongToPlaylist(selectedPlaylist, _currentSong);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플레이리스트에 추가되었습니다')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    String bpmText = 'BPM ${_currentSong.bpm?.toString() ?? '?'}';
    if (_currentSong.initialKey != null &&
        _currentSong.initialKey!.isNotEmpty) {
      bpmText += ' | ${_currentSong.initialKey!}';
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 5),
                        _buildAlbumArt(),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.playlist_add,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    onPressed: _addToPlaylist,
                                    tooltip: '플레이리스트에 추가',
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        _currentSong.title ?? 'Unknown Title',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontSize: 24),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _currentSong.artist ?? 'Unknown Artist',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 16),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 26),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 4),
                                  Text((_currentSong.year?.toString() ?? '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      )),
                                  const SizedBox(width: 16),
                                  Icon(Icons.speed,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 4),
                                  Text('bpm',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text((_currentSong.bpm?.toString() ?? '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      )),
                                  const SizedBox(width: 16),
                                  Icon(Icons.music_note,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 4),
                                  Text('key',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text(
                                      (_currentSong.initialKey?.isNotEmpty ==
                                              true
                                          ? _currentSong.initialKey!
                                          : '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      )),
                                ],
                              ),
                              if (_currentSong.genre != null &&
                                  _currentSong.genre!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _currentSong.genre!,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 18,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        min: 0,
                        max: _duration.inMilliseconds.toDouble(),
                        value: _position.inMilliseconds
                            .clamp(0, _duration.inMilliseconds)
                            .toDouble(),
                        onChanged: (value) async {
                          await _audioPlayer
                              .seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position),
                              style: const TextStyle(color: Colors.white70)),
                          Text(_formatDuration(_duration),
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _loopMode == LoopMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              color: _loopMode == LoopMode.off
                                  ? Colors.white38
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            iconSize: 32,
                            tooltip: _loopMode == LoopMode.off
                                ? '반복 없음'
                                : _loopMode == LoopMode.one
                                    ? '한 곡 반복'
                                    : '전체 반복',
                            onPressed: () {
                              setState(() {
                                if (_loopMode == LoopMode.off) {
                                  _loopMode = LoopMode.all;
                                } else if (_loopMode == LoopMode.all) {
                                  _loopMode = LoopMode.one;
                                } else {
                                  _loopMode = LoopMode.off;
                                }
                                widget.audioPlayer.setLoopMode(_loopMode);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 48,
                            onPressed: _playPrevious,
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow),
                              iconSize: 48,
                              color: Colors.black,
                              onPressed: () async {
                                if (_isPlaying) {
                                  await _audioPlayer.pause();
                                } else {
                                  await _audioPlayer.play();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            iconSize: 48,
                            onPressed: _playNext,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: _isShuffle
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white38,
                            ),
                            iconSize: 32,
                            tooltip: _isShuffle ? '셔플 해제' : '셔플 재생',
                            onPressed: () {
                              setState(() {
                                _isShuffle = !_isShuffle;
                                widget.audioPlayer
                                    .setShuffleModeEnabled(_isShuffle);
                                if (_isShuffle) {
                                  final currentSong =
                                      widget.songs[_currentIndex];
                                  final shuffledSongs =
                                      List<Song>.from(widget.songs)..shuffle();
                                  final newIndex = shuffledSongs.indexWhere(
                                      (song) => song == currentSong);
                                  setState(() {
                                    widget.songs.clear();
                                    widget.songs.addAll(shuffledSongs);
                                    _currentIndex = newIndex;
                                    _currentSong = widget.songs[_currentIndex];
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 86),
                    ],
                  ),
                ),
              ],
            ),
            DraggableScrollableSheet(
              controller: draggableController,
              initialChildSize: 0.04,
              minChildSize: 0.04,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: CustomScrollView(
                    controller: scrollController, // 중요!
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final song = widget.songs[idx];
                            final isCurrent = idx == _currentIndex;
                            return SongListTile(
                              song: song,
                              showBpm: true,
                              selected: isCurrent,
                              onTap: () {
                                setState(() {
                                  _currentIndex = idx;
                                  _currentSong = widget.songs[_currentIndex];
                                });
                                _initAudioPlayer();
                              },
                            );
                          },
                          childCount: widget.songs.length,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    if (_currentSong.albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _currentSong.albumArt!,
          width: 280,
          height: 280,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.music_note,
          size: 120,
          color: Colors.black,
        ),
      );
    }
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
