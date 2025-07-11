import 'package:flutter/material.dart';
import 'dart:typed_data';

class AlbumArtImage extends StatelessWidget {
  final Uint8List? albumArt;
  final double size;
  final double borderRadius;
  final Color? placeholderColor;
  final IconData? placeholderIcon;

  const AlbumArtImage({
    super.key,
    required this.albumArt,
    this.size = 56,
    this.borderRadius = 6,
    this.placeholderColor,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          albumArt!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: placeholderColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          placeholderIcon ?? Icons.music_note,
          color: Colors.black,
          size: size * 0.57,
        ),
      );
    }
  }
}
