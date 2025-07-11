import 'package:flutter/material.dart';
import '../services/metadata_service.dart';
import '../models/song.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/like_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/bpm_filter_bar.dart';
import '../widgets/song_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final metadataService = MetadataService();
  late Future<List<Song>> _songsFuture;
  double _bpmMin = 0;
  double _bpmMax = 250;
  RangeValues get _bpmRange => RangeValues(_bpmMin, _bpmMax);

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  Future<List<Song>> _loadSongs() async {
    final musicDir = await _getMusicDirectory();
    return metadataService.getSongsFromDirectory(musicDir);
  }

  Future<String> _getMusicDirectory() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Music/';
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
      return '';
    }
  }

  Future<void> _pickAndAddMusicFiles() async {
    List<String> filePaths = [];
    if (Platform.isIOS) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: true,
      );
      if (result != null) {
        filePaths = result.paths.whereType<String>().toList();
      }
    } else if (Platform.isAndroid) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: true,
        withData: false,
      );
      if (result != null) {
        filePaths = result.paths.whereType<String>().toList();
      }
    }
    if (filePaths.isNotEmpty) {
      final musicDir = await _getMusicDirectory();
      final destDir = Directory(musicDir);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      for (final path in filePaths) {
        final file = File(path);
        final fileName = file.uri.pathSegments.last;
        await file.copy('${destDir.path}/$fileName');
      }
      setState(() {
        _songsFuture = _loadSongs();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음악 파일이 추가되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('HOME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            onPressed: _pickAndAddMusicFiles,
            tooltip: '음악 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          // BMP 필터 슬라이더 UI
          BpmFilterBar(
            min: 0,
            max: 250,
            divisions: 250,
            values: _bpmRange,
            onChanged: (values) {
              setState(() {
                _bpmMin = values.start;
                _bpmMax = values.end;
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<Song>>(
              future: _songsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }

                final songs = snapshot.data ?? [];
                // 전체 곡 리스트를 PlaylistProvider에 전달
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<PlaylistProvider>(context, listen: false)
                      .setAllSongs(songs);
                });
                final filteredSongs = songs.where((song) {
                  final bpm = song.bpm ?? 0;
                  return bpm >= _bpmMin && bpm <= _bpmMax;
                }).toList();
                return Consumer<LikeProvider>(
                  builder: (context, likeProvider, _) {
                    return SongListView(
                      songs: filteredSongs,
                      showBpm: true,
                      showLikeButton: false, // 홈에서는 하트 숨김
                      onTap: (song, index) {
                        final audioProvider =
                            Provider.of<AudioProvider>(context, listen: false);
                        audioProvider.playSong(filteredSongs, index);
                      },
                      onLike: (song) {
                        likeProvider.likeSong(song);
                      },
                      onUnlike: (song) {
                        likeProvider.unlikeSong(song);
                      },
                      getLikeInfo: (song) {
                        return (
                          isLiked: likeProvider.isSongLiked(song.filePath),
                          likeCount: likeProvider.getLikeCount(song.filePath),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
