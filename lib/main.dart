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
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Miniplayer(
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
                        return GestureDetector(
                          onTap: () {
                            _miniplayerController.animateToHeight(
                                state: PanelState.MAX);
                          },
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
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
        );
      },
    );
  }
}
