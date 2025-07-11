import 'package:flutter/material.dart';
import '../models/song.dart';
import 'song_list_tile.dart';

class SongListView extends StatelessWidget {
  final List<Song> songs;
  final Function(Song, int)? onTap;
  final EdgeInsets? padding;
  final bool showBpm;
  final bool showCard;

  const SongListView({
    super.key,
    required this.songs,
    this.onTap,
    this.padding,
    this.showBpm = true,
    this.showCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ??
          const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 60 + 24),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];

        if (showCard) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SongListTile(
              song: song,
              showBpm: showBpm,
              onTap: onTap != null ? () => onTap!(song, index) : null,
            ),
          );
        } else {
          return SongListTile(
            song: song,
            showBpm: showBpm,
            onTap: onTap != null ? () => onTap!(song, index) : null,
          );
        }
      },
    );
  }
}
