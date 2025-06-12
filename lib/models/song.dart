import 'dart:typed_data';

class Song {
  final String filePath;
  final String? artist;
  final String? title;
  final int? bpm;
  final int? year;
  final String? genre;
  final Uint8List? albumArt;

  Song({
    required this.filePath,
    this.artist,
    this.title,
    this.bpm,
    this.year,
    this.genre,
    this.albumArt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      filePath: json['filePath'] as String,
      artist: json['artist'] as String?,
      title: json['title'] as String?,
      bpm: json['bpm'] as int?,
      year: json['year'] as int?,
      genre: json['genre'] as String?,
      albumArt: json['albumArt'] as Uint8List?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'artist': artist,
      'title': title,
      'bpm': bpm,
      'year': year,
      'genre': genre,
      'albumArt': albumArt,
    };
  }
}
