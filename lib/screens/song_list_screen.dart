import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/metadata_service.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import '../services/google_drive_service.dart';

class SongListScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final void Function(List<Song> songs, int index)? playSong;

  const SongListScreen({
    super.key,
    required this.playlistService,
    this.playSong,
  });

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final MetadataService _metadataService = MetadataService();
  List<Song> _songs = [];
  bool _isLoading = false;
  bool _showFilter = false;
  final double _bpmMin = 0;
  final double _bpmMax = 300;
  RangeValues _bpmRange = const RangeValues(0, 300);

  List<Song> get _filteredSongs {
    return _songs.where((song) {
      final bpm = song.bpm ?? 0;
      return bpm >= _bpmRange.start && bpm <= _bpmRange.end;
    }).toList();
  }

  Future<void> _selectDirectory() async {
    try {
      setState(() => _isLoading = true);

      // Documents 폴더 경로 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      print('Music 폴더 경로: ${musicDir.path}');

      // MP3 파일 목록 가져오기
      final songs = await _metadataService.getSongsFromDirectory(musicDir.path);
      print('찾은 MP3 파일 수: ${songs.length}');

      setState(() {
        _songs = songs;
      });
    } catch (e) {
      print('에러 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addToPlaylist(Song song) async {
    final playlists = await widget.playlistService.getPlaylists();

    if (playlists.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('플레이리스트 없음'),
          content: const Text('새 플레이리스트를 만들겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('생성'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistsScreen(
                playlistService: widget.playlistService,
              ),
            ),
          );
        }
      }
      return;
    }

    final selectedPlaylist = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length}곡'),
                onTap: () => Navigator.pop(context, playlist.name),
              );
            },
          ),
        ),
      ),
    );

    if (selectedPlaylist != null) {
      await widget.playlistService.addSongToPlaylist(selectedPlaylist, song);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플레이리스트에 추가되었습니다')),
        );
      }
    }
  }

  Future<void> _pickAndAddMp3File() async {
    const typeGroup = XTypeGroup(label: 'mp3', extensions: ['mp3']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      final fileName = file.name;
      final newFile = File('${musicDir.path}/$fileName');
      await File(file.path).copy(newFile.path);
      // 새로 추가된 파일까지 포함해 리스트 갱신
      await _selectDirectory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MP3 파일이 추가되었습니다')),
        );
      }
    }
  }

  Future<void> _addFromGoogleDrive() async {
    try {
      final driveService = GoogleDriveService();

      // 폴더 ID 입력 다이얼로그
      final folderId = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('구글 드라이브 폴더 ID'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '폴더 ID를 입력하세요',
                helperText: '구글 드라이브 폴더의 URL에서 /folders/ 다음에 오는 ID를 입력하세요',
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );

      if (folderId == null || folderId.isEmpty) return;

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 폴더 내 MP3 파일 목록 가져오기
      final files = await driveService.listFilesInFolder(folderId);

      // 각 파일 다운로드
      for (final file in files) {
        await driveService.downloadAndSaveFile(file.id!, file.name!);
      }

      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 리스트 갱신
      await _selectDirectory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${files.length}개의 MP3 파일이 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Widget buildSongLeading(Song song) {
    if (song.albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          song.albumArt!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.music_note,
          color: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MP3 Player'),
        leading: IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: () {
            setState(() {
              _showFilter = !_showFilter;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            onPressed: _pickAndAddMp3File,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _isLoading ? null : _selectDirectory,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: _addFromGoogleDrive,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('BPM 범위',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Text(
                          '${_bpmRange.start.round()} - ${_bpmRange.end.round()}'),
                    ],
                  ),
                  RangeSlider(
                    min: _bpmMin,
                    max: _bpmMax,
                    divisions: 60,
                    values: _bpmRange,
                    labels: RangeLabels(
                      _bpmRange.start.round().toString(),
                      _bpmRange.end.round().toString(),
                    ),
                    onChanged: (range) {
                      setState(() {
                        _bpmRange = range;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _filteredSongs.isEmpty
                ? const Center(child: Text('해당 BPM 범위에 곡이 없습니다'))
                : ListView.builder(
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: buildSongLeading(song),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title ?? 'Unknown Title',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist ?? 'Unknown Artist',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (song.bpm != null)
                                    Text(
                                      'BPM ${song.bpm}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  if (song.bpm != null && song.year != null)
                                    const Text(' / ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white54)),
                                  if (song.year != null)
                                    Text(
                                      '${song.year}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.genre ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () => _addToPlaylist(song),
                              ),
                              const Icon(Icons.play_arrow),
                            ],
                          ),
                          onTap: () {
                            if (widget.playSong != null) {
                              widget.playSong!(_filteredSongs, index);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
