import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'dart:io';

enum RepeatMode { none, all, one }

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  List<Song> _currentSongList = [];
  List<Song> _originalSongList = []; // 셔플을 위한 원본 리스트
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isShuffled = false;

  AudioProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _handleSongEnd();
      }
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
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;

  void _handleSongEnd() async {
    // print(
    //     'Song ended. Repeat mode: $_repeatMode, Current index: $_currentIndex, Total songs: ${_currentSongList.length}');
    switch (_repeatMode) {
      case RepeatMode.none:
        // print('Repeat mode: NONE');
        if (_currentIndex < _currentSongList.length - 1) {
          // print('Playing next song');
          await playNext();
        } else {
          // print('Last song reached, stopping');
        }
        break;
      case RepeatMode.all:
        // print('Repeat mode: ALL');
        if (_currentIndex < _currentSongList.length - 1) {
          // print('Playing next song');
          await playNext();
        } else {
          // print('Restarting playlist from beginning');
          await playSong(_currentSongList, 0);
        }
        break;
      case RepeatMode.one:
        // print('Repeat mode: ONE - replaying current song');
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
        break;
    }
  }

  void toggleRepeatMode() {
    // print('toggleRepeatMode called. Current mode: $_repeatMode');
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        // print('Changed to: ALL');
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        // print('Changed to: ONE');
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        // print('Changed to: NONE');
        break;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    if (_currentSongList.isEmpty) return;

    if (_isShuffled) {
      // 셔플 해제: 원본 순서로 복원
      _currentSongList = List.from(_originalSongList);
      // 현재 곡의 인덱스를 원본 리스트에서 찾아서 설정
      final currentSongPath = _currentSong?.filePath;
      if (currentSongPath != null) {
        final originalIndex = _originalSongList
            .indexWhere((song) => song.filePath == currentSongPath);
        if (originalIndex != -1) {
          _currentIndex = originalIndex;
        }
      }
      _isShuffled = false;
    } else {
      // 셔플 활성화
      _originalSongList = List.from(_currentSongList);
      final currentSong = _currentSongList[_currentIndex];
      _currentSongList.shuffle();
      // 현재 곡을 첫 번째로 이동
      _currentSongList.remove(currentSong);
      _currentSongList.insert(0, currentSong);
      _currentIndex = 0;
      _isShuffled = true;
    }
    notifyListeners();
  }

  Future<void> playSong(List<Song> songs, int index) async {
    _currentSongList = songs;
    _originalSongList = List.from(songs);
    _currentIndex = index;
    _currentSong = songs[index];

    // 파일 존재 여부 체크
    if (!File(_currentSong!.filePath).existsSync()) {
      // print('파일이 존재하지 않습니다: \\${_currentSong!.filePath}');
      return;
    }

    try {
      await _audioPlayer.setFilePath(_currentSong!.filePath);
      await _audioPlayer.play();
    } catch (e) {
      // print('Error playing song: $e');
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    // print(
    //     'playNext called. Current index: $_currentIndex, Total songs: ${_currentSongList.length}');
    if (_currentIndex < _currentSongList.length - 1) {
      // print(
      //     'Playing next song at index: $_currentIndex, Song: ${_currentSong?.title}');
      _currentIndex++;
      _currentSong = _currentSongList[_currentIndex];
      // print(
      //     'Playing next song at index: $_currentIndex, Song: ${_currentSong?.title}');

      // 파일 존재 여부 체크
      if (!File(_currentSong!.filePath).existsSync()) {
        // print('파일이 존재하지 않습니다: \\${_currentSong!.filePath}');
        return;
      }

      try {
        await _audioPlayer.setFilePath(_currentSong!.filePath);
        await _audioPlayer.play();
        // print('Successfully started playing next song');
      } catch (e) {
        // print('Error playing song: $e');
      }
      notifyListeners();
    } else {
      // print('Already at last song, cannot play next');
    }
  }

  Future<void> playPrevious() async {
    // print('playPrevious called. Current index: $_currentIndex');
    if (_currentIndex > 0) {
      // print(
      //     'Playing previous song at index: $_currentIndex, Song: ${_currentSong?.title}');
      _currentIndex--;
      _currentSong = _currentSongList[_currentIndex];
      // print(
      //     'Playing previous song at index: $_currentIndex, Song: ${_currentSong?.title}');

      // 파일 존재 여부 체크
      if (!File(_currentSong!.filePath).existsSync()) {
        // print('파일이 존재하지 않습니다: \\${_currentSong!.filePath}');
        return;
      }

      try {
        await _audioPlayer.setFilePath(_currentSong!.filePath);
        await _audioPlayer.play();
        // print('Successfully started playing previous song');
      } catch (e) {
        // print('Error playing song: $e');
      }
      notifyListeners();
    } else {
      // print('Already at first song, cannot play previous');
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
