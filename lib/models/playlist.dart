import 'song.dart';

class Playlist {
  final String name;
  final List<Song> songs;

  Playlist({
    required this.name,
    List<Song>? songs,
  }) : songs = songs ?? [];

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'] as String,
      songs: (json['songs'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'songs': songs.map((song) => song.toJson()).toList(),
    };
  }

  Playlist copyWith({
    String? name,
    List<Song>? songs,
  }) {
    return Playlist(
      name: name ?? this.name,
      songs: songs ?? this.songs,
    );
  }
}
