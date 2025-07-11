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

  // 좋아요 관련 필드 (UI 렌더링용, 실제 데이터는 Provider/DB에서 관리)
  final bool isLiked;
  final int likeCount;

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
    this.isLiked = false,
    this.likeCount = 0,
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
      bpm: json['bpm'] is int
          ? json['bpm'] as int
          : int.tryParse(json['bpm']?.toString() ?? ''),
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse(json['year']?.toString() ?? ''),
      genre: json['genre'] as String?,
      albumArt: albumArt,
      duration: json['duration'] is int
          ? json['duration'] as int
          : int.tryParse(json['duration']?.toString() ?? ''),
      initialKey: json['initialKey'] as String?,
      isLiked: json['isLiked'] ?? false,
      likeCount: json['likeCount'] ?? 0,
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
      'isLiked': isLiked,
      'likeCount': likeCount,
    };
  }

  Song copyWith({
    String? filePath,
    String? artist,
    String? title,
    String? album,
    int? bpm,
    int? year,
    String? genre,
    Uint8List? albumArt,
    int? duration,
    String? initialKey,
    bool? isLiked,
    int? likeCount,
  }) {
    return Song(
      filePath: filePath ?? this.filePath,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      album: album ?? this.album,
      bpm: bpm ?? this.bpm,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      albumArt: albumArt ?? this.albumArt,
      duration: duration ?? this.duration,
      initialKey: initialKey ?? this.initialKey,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
