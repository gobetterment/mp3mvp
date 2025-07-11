import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();

  factory GoogleDriveService() {
    return _instance;
  }

  GoogleDriveService._internal() {
    _initializeGoogleSignIn();
  }

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.readonly',
  ];

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  bool _isInitialized = false;

  void _initializeGoogleSignIn() {
    try {
      if (!_isInitialized) {
        // GoogleSignIn 초기화 전에 잠시 대기
        Future.delayed(const Duration(milliseconds: 50), () {
          try {
            _googleSignIn = GoogleSignIn(scopes: _scopes);
            _isInitialized = true;
            // print('GoogleSignIn initialized successfully');
          } catch (e) {
            // print('GoogleSignIn initialization error in delayed call: $e');
            _isInitialized = false;
          }
        });
      }
    } catch (e) {
      // print('GoogleSignIn initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<bool> signIn() async {
    try {
      // GoogleSignIn이 초기화되지 않았다면 다시 초기화 시도
      if (!_isInitialized || _googleSignIn == null) {
        _initializeGoogleSignIn();

        // 초기화가 완료될 때까지 최대 3초 대기
        int attempts = 0;
        while ((_googleSignIn == null || !_isInitialized) && attempts < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        if (_googleSignIn == null) {
          // print('Failed to initialize GoogleSignIn after multiple attempts');
          return false;
        }
      }

      // 이미 로그인되어 있는지 확인
      final isSignedIn = await _googleSignIn!.isSignedIn();
      if (isSignedIn) {
        // print('User is already signed in');
        await _initializeDriveApi();
        return true;
      }

      // 새로운 로그인 시도
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();
      if (account == null) {
        // print('User cancelled sign in');
        return false;
      }

      // print('Sign in successful for user: ${account.email}');
      await _initializeDriveApi();
      return true;
    } catch (e) {
      // print('Google Sign In Error: $e');
      // 에러 발생 시 GoogleSignIn 재초기화
      _isInitialized = false;
      _googleSignIn = null;
      return false;
    }
  }

  Future<void> _initializeDriveApi() async {
    try {
      if (_googleSignIn == null) return;

      GoogleSignInAccount? currentUser = _googleSignIn!.currentUser;
      if (currentUser == null) {
        currentUser = await _googleSignIn!.signInSilently();
        if (currentUser == null) {
          // print('No signed-in user found');
          return;
        }
      }

      final GoogleSignInAuthentication auth = await currentUser.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        // print('Access token is null');
        return;
      }

      final headers = await currentUser.authHeaders;
      final client = GoogleAuthClient(headers);
      _driveApi = drive.DriveApi(client);
      // print('Drive API initialized successfully');
    } catch (e) {
      // print('Error initializing Drive API: $e');
      _driveApi = null;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
        // print('User signed out successfully');
      }
      _driveApi = null;
    } catch (e) {
      // print('Sign out error: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      if (_googleSignIn == null) {
        _initializeGoogleSignIn();
        if (_googleSignIn == null) return false;
      }

      final isSignedIn = await _googleSignIn!.isSignedIn();
      if (isSignedIn) {
        // Drive API도 초기화되어 있는지 확인
        if (_driveApi == null) {
          await _initializeDriveApi();
        }
      }
      return isSignedIn && _driveApi != null;
    } catch (e) {
      // print('isSignedIn error: $e');
      return false;
    }
  }

  Future<List<drive.File>> getMp3Files({String? folderId}) async {
    if (_driveApi == null) {
      throw Exception(
          'Google Drive API not initialized. Please sign in first.');
    }

    try {
      String query = "mimeType='audio/mpeg' and trashed=false";
      if (folderId != null) {
        query += " and '$folderId' in parents";
      }

      final response = await _driveApi!.files.list(
        q: query,
        $fields: 'files(id,name,size,parents)',
        orderBy: 'name',
      );

      return response.files ?? [];
    } catch (e) {
      // print('Error fetching MP3 files: $e');
      rethrow;
    }
  }

  Future<List<drive.File>> getFolders({String? folderId}) async {
    if (_driveApi == null) {
      throw Exception(
          'Google Drive API not initialized. Please sign in first.');
    }

    try {
      String parentQuery =
          folderId != null ? "'$folderId' in parents" : "'root' in parents";
      final response = await _driveApi!.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and trashed=false and $parentQuery",
        $fields: 'files(id,name,parents)',
        orderBy: 'name',
      );

      return response.files ?? [];
    } catch (e) {
      // print('Error fetching folders: $e');
      rethrow;
    }
  }

  Future<File> downloadFile(drive.File file) async {
    if (_driveApi == null) {
      throw Exception(
          'Google Drive API not initialized. Please sign in first.');
    }

    try {
      // 앱 문서 디렉토리 가져오기
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${appDir.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // 파일 다운로드
      final media = await _driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 로컬 파일 경로
      final localFile = File('${musicDir.path}/${file.name}');

      // 파일 저장
      final fileStream = localFile.openWrite();
      await for (final chunk in media.stream) {
        fileStream.add(chunk);
      }
      await fileStream.close();

      return localFile;
    } catch (e) {
      // print('Error downloading file: $e');
      rethrow;
    }
  }

  Future<void> downloadMultipleFiles(List<drive.File> files,
      Function(int current, int total) onProgress) async {
    for (int i = 0; i < files.length; i++) {
      try {
        await downloadFile(files[i]);
        onProgress(i + 1, files.length);
      } catch (e) {
        // print('Error downloading ${files[i].name}: $e');
        // 개별 파일 다운로드 실패는 무시하고 계속 진행
      }
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
