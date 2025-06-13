import 'package:flutter/material.dart';
import '../services/metadata_service.dart';
import '../models/song.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final metadataService = MetadataService();
  late Future<List<Song>> _songsFuture;
  double _minBpm = 0;
  double _maxBpm = 300;

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
      appBar: AppBar(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('BPM'),
                Expanded(
                  child: RangeSlider(
                    min: 0,
                    max: 300,
                    divisions: 60,
                    values: RangeValues(_minBpm, _maxBpm),
                    onChanged: (values) {
                      setState(() {
                        _minBpm = values.start;
                        _maxBpm = values.end;
                      });
                    },
                    labels:
                        RangeLabels('${_minBpm.round()}', '${_maxBpm.round()}'),
                  ),
                ),
                Text('${_minBpm.round()} - ${_maxBpm.round()}'),
              ],
            ),
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
                final filteredSongs = songs.where((song) {
                  final bpm = song.bpm ?? 0;
                  return bpm >= _minBpm && bpm <= _maxBpm;
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight + 60 + 24),
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final audioProvider = Provider.of<AudioProvider>(
                              context,
                              listen: false);
                          await audioProvider.playSong(filteredSongs, index);
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 앨범 커버
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.albumArt != null
                                  ? Image.memory(song.albumArt!,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      child: const Icon(Icons.music_note,
                                          size: 32, color: Colors.white70),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // 정보 영역
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 타이틀
                                  Text(
                                    song.title ?? 'Unknown Title',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // 아티스트 | 연도
                                  Text(
                                    [
                                      song.artist ?? 'Unknown Artist',
                                      if (song.year != null) '| ${song.year}'
                                    ].join(' '),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // 장르
                                  Text(
                                    song.genre ?? '-',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white60),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // BPM 뱃지 (작게, 아이콘 없이)
                            if (song.bpm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'BPM ${song.bpm}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
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
