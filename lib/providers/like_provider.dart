import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'dart:convert';

class LikeProvider with ChangeNotifier {
  // filePath를 key로 좋아요 상태/카운트 관리
  Map<String, int> _likeCounts = {};
  SharedPreferences? _prefs;

  LikeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final likeCountsJson = _prefs?.getString('likeCounts');
    if (likeCountsJson != null) {
      _likeCounts = Map<String, int>.from(json.decode(likeCountsJson));
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _prefs?.setString('likeCounts', json.encode(_likeCounts));
  }

  int getLikeCount(String filePath) => _likeCounts[filePath] ?? 0;
  bool isSongLiked(String filePath) => getLikeCount(filePath) > 0;

  void likeSong(Song song) {
    final path = song.filePath;
    _likeCounts[path] = (_likeCounts[path] ?? 0) + 1;
    _saveToPrefs();
    notifyListeners();
  }

  void unlikeSong(Song song) {
    final path = song.filePath;
    _likeCounts[path] = 0;
    _saveToPrefs();
    notifyListeners();
  }

  // 좋아요 곡 리스트 반환
  List<String> get likedSongPaths =>
      _likeCounts.entries.where((e) => e.value > 0).map((e) => e.key).toList();

  // 곡 삭제 시 좋아요 정보도 함께 삭제
  void removeSong(String filePath) {
    _likeCounts.remove(filePath);
    _saveToPrefs();
    notifyListeners();
  }
}
