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
  final Widget? trailing;

  const SongListTile({
    super.key,
    required this.song,
    this.showBpm = false,
    this.selected = false,
    this.onTap,
    this.showCheckbox = false,
    this.checked = false,
    this.onCheckedChanged,
    this.trailing,
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

    final subtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
    );

    final titleRow = Text(
      song.title ?? 'Unknown Title',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 앨범아트/체크박스
              if (showCheckbox)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: onCheckedChanged,
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    leading,
                  ],
                )
              else
                leading,
              const SizedBox(width: 12),
              // 정보(타이틀, 아티스트/연도, 장르)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: titleRow),
                      ],
                    ),
                    subtitle,
                  ],
                ),
              ),
              // BPM 뱃지
              if (showBpm && song.bpm != null)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  constraints: const BoxConstraints(minWidth: 72),
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
                ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
