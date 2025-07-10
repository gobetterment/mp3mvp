import 'package:flutter/material.dart';
import '../models/song.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final bool showBpm;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final Widget? leading;

  const SongListTile({
    super.key,
    required this.song,
    this.showBpm = true,
    this.trailing,
    this.onTap,
    this.leading,
  });

  Widget _defaultLeading(BuildContext context) {
    if (song.albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          song.albumArt!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: leading ?? _defaultLeading(context),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.title ?? 'Unknown Title',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            song.artist ?? 'Unknown Artist',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (showBpm && song.bpm != null)
                Text(
                  'BPM ${song.bpm}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              if (showBpm && song.bpm != null && song.year != null)
                const Text(
                  ' / ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              if (song.year != null)
                Text(
                  '${song.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            song.genre ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
