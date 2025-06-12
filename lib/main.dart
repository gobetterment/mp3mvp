import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/song_list_screen.dart';
import 'screens/playlists_screen.dart';
import 'services/playlist_service.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song.dart';
import 'screens/player_screen.dart';
import 'widgets/mini_player_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final playlistService = PlaylistService(prefs);

  runApp(MyApp(playlistService: playlistService));
}

class MyApp extends StatelessWidget {
  final PlaylistService playlistService;

  const MyApp({super.key, required this.playlistService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP3 Player',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954), // Spotify green
          secondary: Colors.white, // Spotify dark background
          surface: Color(0xFF282828),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
      home: MainScreen(playlistService: playlistService),
    );
  }
}

class MainScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const MainScreen({super.key, required this.playlistService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  List<Song> _currentSongList = [];
  int _currentIndex = 0;

  void playSong(List<Song> songs, int index) async {
    setState(() {
      _currentSongList = songs;
      _currentIndex = index;
      _currentSong = songs[index];
    });
    await _audioPlayer.setFilePath(_currentSong!.filePath);
    await _audioPlayer.play();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              SongListScreen(
                playlistService: widget.playlistService,
                playSong: playSong,
              ),
              PlaylistsScreen(
                playlistService: widget.playlistService,
                playSong: playSong,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.music_note),
                label: '음악',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play),
                label: '플레이리스트',
              ),
            ],
          ),
        ),
        if (_currentSong != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayerBar(
              song: _currentSong!,
              audioPlayer: _audioPlayer,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        songs: _currentSongList,
                        currentIndex: _currentIndex,
                        playlistService: widget.playlistService,
                        audioPlayer: _audioPlayer,
                      ),
                    ));
              },
            ),
          ),
      ],
    );
  }
}
