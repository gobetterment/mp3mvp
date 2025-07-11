import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'dart:io';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  List<Song> _currentSongList = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  Song? get currentSong => _currentSong;
  List<Song> get currentSongList => _currentSongList;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> playSong(List<Song> songs, int index) async {
    _currentSongList = songs;
    _currentIndex = index;
    _currentSong = songs[index];

    // 파일 존재 여부 체크
    if (!File(_currentSong!.filePath).existsSync()) {
      print('파일이 존재하지 않습니다: \\${_currentSong!.filePath}');
      // 필요시 사용자에게 안내 메시지 추가
      return;
    }

    try {
      await _audioPlayer.setFilePath(_currentSong!.filePath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_currentIndex < _currentSongList.length - 1) {
      await playSong(_currentSongList, _currentIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      await playSong(_currentSongList, _currentIndex - 1);
    }
  }

  void setIsPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
