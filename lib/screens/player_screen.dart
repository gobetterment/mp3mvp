import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
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
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.playlist_add),
                        onPressed: _addToPlaylist,
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          _buildAlbumArt(),
                          const SizedBox(height: 24),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                Text(
                                  _currentSong.title ?? 'Unknown Title',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: 24),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
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
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    StatefulBuilder(
                                      builder: (context, setState) {
                                        bool isLiked = false;
                                        return IconButton(
                                          icon: Icon(
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isLiked
                                                ? Colors.red
                                                : Colors.white70,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              isLiked = !isLiked;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.playlist_add,
                                          color: Colors.white70),
                                      onPressed: _addToPlaylist,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'BPM ${_currentSong.bpm?.toString() ?? '?'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_currentSong.genre != null &&
                                    _currentSong.genre!.isNotEmpty)
                                  Text(
                                    _currentSong.genre!,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                icon: Icon(_isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
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
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    final year = _currentSong.year;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (year != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              year.toString(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (_currentSong.albumArt != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _currentSong.albumArt!,
              width: 280,
              height: 280,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
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
          ),
      ],
    );
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
