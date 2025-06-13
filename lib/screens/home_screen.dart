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
        title: const Text('음악'),
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
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    return ListTile(
                      leading: song.albumArt != null
                          ? Image.memory(song.albumArt!, width: 50, height: 50)
                          : const Icon(Icons.music_note),
                      title: Text(song.title ?? 'Unknown Title'),
                      subtitle: Text(
                          '${song.artist ?? 'Unknown Artist'}  |  BPM: ${song.bpm ?? '-'}'),
                      onTap: () async {
                        final audioProvider =
                            Provider.of<AudioProvider>(context, listen: false);
                        await audioProvider.playSong(filteredSongs, index);
                        setState(() {});
                        audioProvider.audioPlayer.play();
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
