import 'package:flutter/material.dart';
import '../models/song.dart';
import 'song_list_tile.dart';

// 좋아요 정보를 담는 튜플 타입
typedef LikeInfo = ({bool isLiked, int likeCount});

class SongListView extends StatelessWidget {
  final List<Song> songs;
  final Function(Song, int)? onTap;
  final EdgeInsets? padding;
  final bool showBpm;
  final bool showCard;
  final bool showLikeButton;
  final Function(Song)? onLike;
  final Function(Song)? onUnlike;
  final LikeInfo Function(Song)? getLikeInfo;

  const SongListView({
    super.key,
    required this.songs,
    this.onTap,
    this.padding,
    this.showBpm = true,
    this.showCard = false,
    this.showLikeButton = false,
    this.onLike,
    this.onUnlike,
    this.getLikeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ??
          const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 60 + 24),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];

        final likeInfo =
            getLikeInfo?.call(song) ?? (isLiked: false, likeCount: 0);

        if (showCard) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SongListTile(
              song: song,
              showBpm: showBpm,
              showLikeButton: showLikeButton,
              isLiked: likeInfo.isLiked,
              likeCount: likeInfo.likeCount,
              onLike: onLike != null ? () => onLike!(song) : null,
              onUnlike: onUnlike != null ? () => onUnlike!(song) : null,
              onTap: onTap != null ? () => onTap!(song, index) : null,
            ),
          );
        } else {
          return SongListTile(
            song: song,
            showBpm: showBpm,
            showLikeButton: showLikeButton,
            isLiked: likeInfo.isLiked,
            likeCount: likeInfo.likeCount,
            onLike: onLike != null ? () => onLike!(song) : null,
            onUnlike: onUnlike != null ? () => onUnlike!(song) : null,
            onTap: onTap != null ? () => onTap!(song, index) : null,
          );
        }
      },
    );
  }
}
