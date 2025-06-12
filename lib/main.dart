import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/song_list_screen.dart';
import 'screens/playlists_screen.dart';
import 'services/playlist_service.dart';

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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1DB954), // Spotify green
          secondary: Colors.white, // Spotify dark background
          surface: const Color(0xFF282828),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SongListScreen(playlistService: widget.playlistService),
          PlaylistsScreen(playlistService: widget.playlistService),
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
    );
  }
}
