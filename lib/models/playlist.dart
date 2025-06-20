import 'song.dart';

class Playlist {
  final String name;
  final List<Song> songs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;

  Playlist({
    required this.name,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.description,
  })  : songs = songs ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'] as String,
      songs: (json['songs'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'description': description,
    };
  }

  Playlist copyWith({
    String? name,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return Playlist(
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }
}
