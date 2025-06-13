import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  List<Song> _currentSongList = [];
  int _currentIndex = 0;
  bool _isPlaying = false;

  AudioProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  Song? get currentSong => _currentSong;
  List<Song> get currentSongList => _currentSongList;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;

  Future<void> playSong(List<Song> songs, int index) async {
    _currentSongList = songs;
    _currentIndex = index;
    _currentSong = songs[index];

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
