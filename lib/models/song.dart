import 'dart:typed_data';

class Song {
  final String filePath;
  final String? artist;
  final String? title;
  final String? album;
  final int? bpm;
  final int? year;
  final String? genre;
  final Uint8List? albumArt;
  final int? duration;
  final String? initialKey;

  Song({
    required this.filePath,
    this.artist,
    this.title,
    this.album,
    this.bpm,
    this.year,
    this.genre,
    this.albumArt,
    this.duration,
    this.initialKey,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final albumArtRaw = json['albumArt'];
    Uint8List? albumArt;
    if (albumArtRaw != null) {
      if (albumArtRaw is Uint8List) {
        albumArt = albumArtRaw;
      } else if (albumArtRaw is List) {
        albumArt = Uint8List.fromList(List<int>.from(albumArtRaw));
      }
    }
    return Song(
      filePath: json['filePath'] as String,
      artist: json['artist'] as String?,
      title: json['title'] as String?,
      album: json['album'] as String?,
      bpm: json['bpm'] as int?,
      year: json['year'] as int?,
      genre: json['genre'] as String?,
      albumArt: albumArt,
      duration: json['duration'] as int?,
      initialKey: json['initialKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'artist': artist,
      'title': title,
      'album': album,
      'bpm': bpm,
      'year': year,
      'genre': genre,
      'albumArt': albumArt,
      'duration': duration,
      'initialKey': initialKey,
    };
  }
}
