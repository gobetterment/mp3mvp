import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import 'playlists_screen.dart';
import '../widgets/song_list_view.dart';
import '../widgets/album_art_image.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';

class PlayerScreen extends StatelessWidget {
  final List<Song> songs;
  final int currentIndex;

  const PlayerScreen({
    super.key,
    required this.songs,
    required this.currentIndex,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong ?? songs[currentIndex];
    final position = audioProvider.position;
    final duration = audioProvider.duration;
    final isPlaying = audioProvider.isPlaying;
    final currentIdx = audioProvider.currentIndex;
    final songList = audioProvider.currentSongList.isNotEmpty
        ? audioProvider.currentSongList
        : songs;

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
                        AlbumArtImage(
                          albumArt: song.albumArt,
                          size: 280,
                          borderRadius: 8,
                          placeholderColor:
                              Theme.of(context).colorScheme.primary,
                          placeholderIcon: Icons.music_note,
                        ),
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
                                    onPressed: () async {
                                      final playlistProvider =
                                          Provider.of<PlaylistProvider>(context,
                                              listen: false);
                                      final playlists =
                                          playlistProvider.playlists;
                                      if (playlists.isEmpty) {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('플레이리스트 없음'),
                                            content:
                                                const Text('새 플레이리스트를 만들겠습니까?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('취소'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('생성'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PlaylistsScreen(),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      final selectedPlaylist =
                                          await showDialog<String>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('플레이리스트 선택'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: playlists.length,
                                              itemBuilder: (context, index) {
                                                final playlist =
                                                    playlists[index];
                                                return ListTile(
                                                  title: Text(playlist.name),
                                                  subtitle: Text(
                                                      '${playlist.songs.length}곡'),
                                                  onTap: () => Navigator.pop(
                                                      context, playlist.name),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                      if (selectedPlaylist != null) {
                                        await playlistProvider
                                            .addSongToPlaylist(
                                                selectedPlaylist, song);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('플레이리스트에 추가되었습니다')),
                                        );
                                      }
                                    },
                                    tooltip: '플레이리스트에 추가',
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        song.title ?? 'Unknown Title',
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
                                song.artist ?? 'Unknown Artist',
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
                                  Text((song.year?.toString() ?? '?'),
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
                                  Text((song.bpm?.toString() ?? '?'),
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
                                      (song.initialKey?.isNotEmpty == true
                                          ? song.initialKey!
                                          : '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      )),
                                ],
                              ),
                              if (song.genre != null && song.genre!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    song.genre!,
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
                        max: duration.inMilliseconds.toDouble(),
                        value: position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                        onChanged: (value) async {
                          await audioProvider.audioPlayer
                              .seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position),
                              style: const TextStyle(color: Colors.white70)),
                          Text(_formatDuration(duration),
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 반복 버튼 등은 필요시 Provider에 추가 구현
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 48,
                            onPressed: () {
                              audioProvider.playPrevious();
                            },
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow),
                              iconSize: 48,
                              color: Colors.black,
                              onPressed: () async {
                                if (isPlaying) {
                                  await audioProvider.audioPlayer.pause();
                                } else {
                                  await audioProvider.audioPlayer.play();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            iconSize: 48,
                            onPressed: () {
                              audioProvider.playNext();
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
                      SliverToBoxAdapter(
                        child: SongListView(
                          songs: songList,
                          showBpm: true,
                          onTap: (song, index) {
                            audioProvider.playSong(songList, index);
                          },
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
}
