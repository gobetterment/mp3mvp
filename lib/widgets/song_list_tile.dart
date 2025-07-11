import 'package:flutter/material.dart';

import '../models/song.dart';
import 'album_art_image.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final bool showBpm;
  final bool selected;
  final VoidCallback? onTap;
  final bool showCheckbox;
  final bool checked;
  final ValueChanged<bool?>? onCheckedChanged;

  const SongListTile({
    super.key,
    required this.song,
    this.showBpm = false,
    this.selected = false,
    this.onTap,
    this.showCheckbox = false,
    this.checked = false,
    this.onCheckedChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget leading = showCheckbox
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: checked,
                onChanged: onCheckedChanged,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              AlbumArtImage(albumArt: song.albumArt),
            ],
          )
        : AlbumArtImage(albumArt: song.albumArt);

    final subtitle = Text(
      [
        song.artist,
        if (song.year != null) song.year.toString(),
      ].where((e) => e != null && e.isNotEmpty).join(' | '),
      style: const TextStyle(fontSize: 13, color: Colors.white70),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final bpmBadge = (showBpm && song.bpm != null)
        ? Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            constraints: const BoxConstraints(minWidth: 72), // 세자리수 기준 고정
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              'BPM ${song.bpm}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          )
        : null;

    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
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
          ),
        ),
        if (bpmBadge != null) bpmBadge,
      ],
    );

    final tile = ListTile(
      leading: leading,
      title: titleRow,
      subtitle: subtitle,
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
