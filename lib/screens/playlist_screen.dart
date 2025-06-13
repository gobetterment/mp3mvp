import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const PlaylistScreen({Key? key, required this.playlistService})
      : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플레이리스트'),
      ),
      body: FutureBuilder<List<Playlist>>(
        future: widget.playlistService.getPlaylists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final playlists = snapshot.data ?? [];
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length}곡'),
                onTap: () {
                  // TODO: Implement playlist view
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new playlist creation
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
