import 'package:flutter/material.dart';
import '../models/song.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              child: const Icon(Icons.music_note, color: Colors.black, size: 32),
            ),
      title: Text(
        song.title ?? 'Unknown Title',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              style: const TextStyle(fontSize: 13, color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
