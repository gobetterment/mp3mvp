import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [
    'https://www.googleapis.com/auth/drive.readonly',
  ]);

  Future<Map<String, String>> _getAuthHeaders() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google 로그인이 필요합니다.');
    return await account.authHeaders;
  }

  Future<List<drive.File>> listFilesInFolder(String folderId) async {
    final headers = await _getAuthHeaders();
    final client = GoogleAuthClient(headers);
    final driveApi = drive.DriveApi(client);

    try {
      final result = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType='audio/mpeg'",
        $fields: 'files(id, name)',
      );
      return result.files ?? [];
    } catch (e) {
      print('Error listing files: $e');
      rethrow;
    }
  }

  Future<void> downloadAndSaveFile(String fileId, String fileName) async {
    final headers = await _getAuthHeaders();
    final client = GoogleAuthClient(headers);
    final driveApi = drive.DriveApi(client);

    try {
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final file = File('${musicDir.path}/$fileName');
      final sink = file.openWrite();
      await for (final data in media.stream) {
        sink.add(data);
      }
      await sink.close();
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
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
