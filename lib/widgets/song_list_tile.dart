import 'package:flutter/material.dart';

import '../models/song.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final bool showBpm;
  final bool selected;
  final VoidCallback? onTap;

  const SongListTile({
    super.key,
    required this.song,
    this.showBpm = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (song.albumArt != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          song.albumArt!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    } else {
      leading = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.music_note, color: Colors.black, size: 32),
      );
    }

    final title = Text(
      song.title ?? 'Unknown Title',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final subtitle = Text(
      [
        song.artist,
        if (song.year != null) song.year.toString(),
      ].where((e) => e != null && e.isNotEmpty).join(' | '),
      style: const TextStyle(fontSize: 13, color: Colors.white70),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget? trailing;
    if (showBpm && song.bpm != null) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'BPM ${song.bpm}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    final tile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );

    return Container(
      color: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
          : Colors.transparent,
      child: tile,
    );
  }
}
