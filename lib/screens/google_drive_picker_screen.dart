import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../services/google_drive_service.dart';
import '../services/metadata_service.dart';
import '../models/song.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GoogleDrivePickerScreen extends StatefulWidget {
  const GoogleDrivePickerScreen({super.key});

  @override
  State<GoogleDrivePickerScreen> createState() =>
      _GoogleDrivePickerScreenState();
}

class _GoogleDrivePickerScreenState extends State<GoogleDrivePickerScreen> {
  late final GoogleDriveService _googleDriveService;
  final MetadataService _metadataService = MetadataService();

  @override
  void initState() {
    super.initState();
    _googleDriveService = GoogleDriveService();
    _checkSignInStatus();
  }

  List<drive.File> _files = [];
  List<drive.File> _folders = [];
  final List<drive.File> _selectedFiles = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  int _downloadProgress = 0;
  int _totalFiles = 0;
  String? _currentFolderId;
  String _currentFolderName = '내 드라이브';
  bool _isSignedIn = false;

  Future<void> _checkSignInStatus() async {
    try {
      final isSignedIn = await _googleDriveService.isSignedIn();
      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
        });
        if (isSignedIn) {
          _loadContent();
        }
      }
    } catch (e) {
      print('Check sign in status error: $e');
      if (mounted) {
        setState(() {
          _isSignedIn = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      // 로그인 시도 전에 잠시 대기하여 UI가 안정화되도록 함
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await _googleDriveService.signIn();
      if (success) {
        setState(() {
          _isSignedIn = true;
        });
        await _loadContent();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구글 로그인에 실패했습니다. 다시 시도해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Sign in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final folders =
          await _googleDriveService.getFolders(folderId: _currentFolderId);
      final files =
          await _googleDriveService.getMp3Files(folderId: _currentFolderId);

      setState(() {
        _folders = folders;
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _navigateToFolder(drive.File folder) async {
    setState(() {
      _currentFolderId = folder.id;
      _currentFolderName = folder.name ?? '알 수 없는 폴더';
    });
    await _loadContent();
  }

  Future<void> _navigateToParent() async {
    if (_currentFolderId == null) return;

    // 상위 폴더 찾기
    final parentFolder = _folders.firstWhere(
      (folder) => folder.id == _currentFolderId,
      orElse: () => drive.File(),
    );

    if (parentFolder.parents != null && parentFolder.parents!.isNotEmpty) {
      setState(() {
        _currentFolderId = parentFolder.parents!.first;
        _currentFolderName = '상위 폴더';
      });
    } else {
      setState(() {
        _currentFolderId = null;
        _currentFolderName = '내 드라이브';
      });
    }
    await _loadContent();
  }

  void _toggleFileSelection(drive.File file) {
    setState(() {
      if (_selectedFiles.any((f) => f.id == file.id)) {
        _selectedFiles.removeWhere((f) => f.id == file.id);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  Future<void> _downloadSelectedFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _totalFiles = _selectedFiles.length;
    });

    try {
      await _googleDriveService.downloadMultipleFiles(
        _selectedFiles,
        (current, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = current;
            });
          }
        },
      );

      // 다운로드된 파일들의 메타데이터 추출
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${appDir.path}/music');
      final songs = await _metadataService.getSongsFromDirectory(musicDir.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedFiles.length}개의 파일이 다운로드되었습니다.')),
        );
        Navigator.pop(context, songs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _selectedFiles.clear();
        });
      }
    }
  }

  String _formatFileSize(dynamic size) {
    int? intSize;
    if (size is int) {
      intSize = size;
    } else if (size is String) {
      intSize = int.tryParse(size);
    }
    if (intSize == null) return '알 수 없음';
    if (intSize < 1024) return '${intSize}B';
    if (intSize < 1024 * 1024)
      return '${(intSize / 1024).toStringAsFixed(1)}KB';
    return '${(intSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_currentFolderName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedFiles.isNotEmpty)
            TextButton(
              onPressed: _isDownloading ? null : _downloadSelectedFiles,
              child: Text(
                '다운로드 (${_selectedFiles.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 로그인 상태 및 진행률 표시
          if (_isDownloading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value:
                        _totalFiles > 0 ? _downloadProgress / _totalFiles : 0,
                    backgroundColor: Colors.grey[700],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '다운로드 중... $_downloadProgress/$_totalFiles',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // 로그인 버튼
          if (!_isSignedIn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signIn,
                icon: const Icon(Icons.login),
                label: const Text('구글 계정으로 로그인'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      // 상위 폴더로 이동 버튼
                      if (_currentFolderId != null)
                        ListTile(
                          leading:
                              const Icon(Icons.folder_open, color: Colors.blue),
                          title: const Text('..',
                              style: TextStyle(color: Colors.white)),
                          subtitle: const Text('상위 폴더로 이동',
                              style: TextStyle(color: Colors.grey)),
                          onTap: _navigateToParent,
                        ),

                      // 전체선택 체크박스 (파일이 있을 때만 표시)
                      if (_files.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _selectedFiles.length == _files.length,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedFiles
                                        ..clear()
                                        ..addAll(_files);
                                    } else {
                                      _selectedFiles.clear();
                                    }
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                              const Text('전체선택',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),

                      // 폴더 목록
                      ..._folders.map((folder) => ListTile(
                            leading:
                                const Icon(Icons.folder, color: Colors.blue),
                            title: Text(folder.name ?? '알 수 없는 폴더',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: const Text('폴더',
                                style: TextStyle(color: Colors.grey)),
                            onTap: () => _navigateToFolder(folder),
                          )),

                      // 파일 목록
                      ..._files.map((file) => ListTile(
                            leading: const Icon(Icons.music_note,
                                color: Colors.green),
                            title: Text(file.name ?? '알 수 없는 파일',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              _formatFileSize(file.size),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Checkbox(
                              value: _selectedFiles.any((f) => f.id == file.id),
                              onChanged: (_) => _toggleFileSelection(file),
                              activeColor: Colors.green,
                            ),
                            onTap: () => _toggleFileSelection(file),
                          )),

                      // 빈 상태 메시지
                      if (_folders.isEmpty && _files.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              '이 폴더에 MP3 파일이 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
