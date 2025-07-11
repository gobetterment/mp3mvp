import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import 'playlists_screen.dart';
import '../widgets/song_list_view.dart';
import '../widgets/album_art_image.dart';
import '../widgets/song_list_tile.dart';
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
                              // 첫 번째 줄: 연도 / BPM / 키
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 4),
                                  Text((song.year?.toString() ?? '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      )),
                                  const SizedBox(width: 16),
                                  Icon(Icons.speed,
                                      size: 14,
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
                                          fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Text((song.bpm?.toString() ?? '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      )),
                                  const SizedBox(width: 16),
                                  Icon(Icons.music_note,
                                      size: 14,
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
                                          fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Text(
                                      (song.initialKey?.isNotEmpty == true
                                          ? song.initialKey!
                                          : '?'),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      )),
                                ],
                              ),
                              // 두 번째 줄: 앨범명
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  song.album ?? 'Unknown Album',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // 세 번째 줄: 장르
                              if (song.genre != null && song.genre!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    song.genre!,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
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
            // 하단 곡 리스트 버튼 추가
            Positioned(
              left: 0,
              right: 0,
              bottom: 20, // 재생 버튼 위에 배치
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.7,
                        minChildSize: 0.5,
                        maxChildSize: 0.9,
                        builder: (context, scrollController) => Column(
                          children: [
                            // 드래그 핸들
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            // 헤더
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.queue_music,
                                    size: 20,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    songList.isNotEmpty
                                        ? '재생 목록 (${songList.length}곡)'
                                        : '재생 목록 없음',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 곡 리스트
                            Expanded(
                              child: songList.isNotEmpty
                                  ? ListView.builder(
                                      controller: scrollController,
                                      itemCount: songList.length,
                                      itemBuilder: (context, index) {
                                        final song = songList[index];
                                        final isCurrentSong =
                                            index == currentIdx;
                                        return SongListTile(
                                          song: song,
                                          showBpm: true,
                                          selected: isCurrentSong,
                                          onTap: () {
                                            audioProvider.playSong(
                                                songList, index);
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.queue_music,
                                            size: 48,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '재생 목록이 비어있습니다',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '홈에서 곡을 재생하면\n여기에 표시됩니다',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          songList.isNotEmpty
                              ? '재생 목록 (${songList.length}곡)'
                              : '재생 목록 없음',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_up,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
