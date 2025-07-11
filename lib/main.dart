import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/audio_provider.dart';
import 'providers/playlist_provider.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings_screen.dart';
import 'services/playlist_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final playlistService = PlaylistService(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioProvider()),
        ChangeNotifierProvider(
            create: (context) => PlaylistProvider(playlistService)),
      ],
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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const HomeScreen(),
      const PlaylistsScreen(),
      const SettingsScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, _) {
        final currentSong = audioProvider.currentSong;
        return Scaffold(
          body: Stack(
            children: [
              Padding(
                padding:
                    EdgeInsets.only(bottom: currentSong != null ? 60.0 : 0.0),
                child: Navigator(
                  key: _navigatorKey,
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => _screens[_selectedIndex],
                    );
                  },
                ),
              ),
              if (currentSong != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            songs: audioProvider.currentSongList,
                            currentIndex: audioProvider.currentIndex,
                            // playlistService 인자 제거
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            leading: currentSong.albumArt != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.memory(
                                      currentSong.albumArt!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.music_note),
                                  ),
                            title: Text(
                              currentSong.title ?? 'Unknown Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              currentSong.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    audioProvider.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          StreamBuilder<Duration?>(
                            stream: audioProvider.audioPlayer.positionStream,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              return StreamBuilder<Duration?>(
                                stream:
                                    audioProvider.audioPlayer.durationStream,
                                builder: (context, snapshot) {
                                  final duration =
                                      snapshot.data ?? Duration.zero;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                    child: ProgressBar(
                                      progress: position,
                                      total: duration,
                                      onSeek: (duration) {
                                        audioProvider.audioPlayer
                                            .seek(duration);
                                      },
                                      barHeight: 2,
                                      thumbRadius: 4,
                                      progressBarColor:
                                          Theme.of(context).colorScheme.primary,
                                      baseBarColor:
                                          Colors.white.withOpacity(0.24),
                                      thumbColor:
                                          Theme.of(context).colorScheme.primary,
                                      timeLabelLocation: TimeLabelLocation.none,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (_navigatorKey.currentState != null &&
                  _navigatorKey.currentState!.canPop()) {
                _navigatorKey.currentState!.popUntil((route) => route.isFirst);
              }
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
        );
      },
    );
  }
}
