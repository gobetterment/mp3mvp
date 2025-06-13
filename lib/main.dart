import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/song_list_screen.dart';
import 'screens/playlists_screen.dart';
import 'services/playlist_service.dart';
import 'package:just_audio/just_audio.dart';
import 'models/song.dart';
import 'screens/player_screen.dart';
import 'widgets/mini_player_bar.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'screens/home_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/settings_screen.dart';
import 'package:marquee/marquee.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final playlistService = PlaylistService(prefs);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AudioProvider(),
      child: MyApp(playlistService: playlistService),
    ),
  );
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _miniplayerController = MiniplayerController();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const HomeScreen(),
      PlaylistScreen(playlistService: widget.playlistService),
      const SettingsScreen(),
    ]);
  }

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
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, _) {
        final currentSong = audioProvider.currentSong;
        return Scaffold(
          body: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => _screens[_selectedIndex],
              );
            },
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentSong != null)
                Miniplayer(
                  controller: _miniplayerController,
                  minHeight: 60,
                  maxHeight: MediaQuery.of(context).size.height,
                  builder: (height, percentage) {
                    if (percentage > 0.5) {
                      return PlayerScreen(
                        songs: audioProvider.currentSongList,
                        currentIndex: audioProvider.currentIndex,
                        playlistService: widget.playlistService,
                        audioPlayer: audioProvider.audioPlayer,
                      );
                    }
                    final currentSong = audioProvider.currentSong;
                    if (currentSong == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        _miniplayerController.animateToHeight(
                            state: PanelState.MAX);
                      },
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: currentSong.albumArt != null
                              ? Image.memory(currentSong.albumArt!,
                                  width: 40, height: 40, fit: BoxFit.cover)
                              : const CircleAvatar(
                                  child: Icon(Icons.music_note)),
                          title: SizedBox(
                            height: 20,
                            child: Marquee(
                              text: currentSong.title ?? 'Unknown Title',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              blankSpace: 40,
                              velocity: 30,
                              pauseAfterRound: const Duration(seconds: 1),
                            ),
                          ),
                          subtitle: Text(
                            currentSong.artist ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  audioProvider.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                onPressed: () async {
                                  if (audioProvider.isPlaying) {
                                    await audioProvider.audioPlayer.pause();
                                    audioProvider.setIsPlaying(false);
                                  } else {
                                    await audioProvider.audioPlayer.play();
                                    audioProvider.setIsPlaying(true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.playlist_play),
                    label: 'Playlist',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
