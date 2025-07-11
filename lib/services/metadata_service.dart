import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:id3_codec/id3_codec.dart';
import '../models/song.dart';

class MetadataService {
  Future<List<Song>> getSongsFromDirectory(String directoryPath) async {
    final songs = <Song>[];
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      return songs;
    }

    final files = await directory
        .list()
        .where((entity) =>
            entity is File && entity.path.toLowerCase().endsWith('.mp3'))
        .cast<File>()
        .toList();

    for (final file in files) {
      try {
        final metadata = readAllMetadata(file);
        if (metadata is Mp3Metadata) {
          final artist = (metadata.bandOrOrchestra ??
                  metadata.leadPerformer ??
                  metadata.conductor ??
                  'Unknown Artist')
              .trim();
          final title = (metadata.songName ??
                  metadata.subtitle ??
                  metadata.contentGroupDescription ??
                  'Unknown Title')
              .trim();
          final album = metadata.album?.trim() ?? '';

          Uint8List? albumArt;
          if (metadata.pictures.isNotEmpty) {
            albumArt = metadata.pictures.first.bytes;
          }

          int? duration;
          if (metadata.duration is int) {
            duration = metadata.duration as int;
          } else if (metadata.duration is String) {
            duration = parseDurationString(metadata.duration as String);
          } else if (metadata.duration is Duration) {
            duration = (metadata.duration as Duration).inSeconds;
          }

          songs.add(Song(
            filePath: file.path,
            artist: artist,
            title: title,
            album: album.isNotEmpty ? album : null,
            bpm: () {
              if (metadata.bpm == null) return null;
              if (metadata.bpm is int) return metadata.bpm as int;
              final parsed = int.tryParse(metadata.bpm.toString());
              return parsed;
            }(),
            year: metadata.year is int
                ? metadata.year
                : int.tryParse(metadata.year?.toString() ?? ''),
            genre: metadata.contentType?.toString(),
            albumArt: albumArt,
            duration: duration,
            initialKey: metadata.initialKey,
          ));
        }
      } catch (e) {
        // print('Error reading metadata for ${file.path}: $e');
        continue;
      }
    }

    return songs;
  }

  static Future<Map<String, dynamic>> getMetadata(String filePath) async {
    try {
      final metadata = readAllMetadata(File(filePath));
      if (metadata is! Mp3Metadata) {
        throw Exception('Not an MP3 file');
      }

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final decoder = ID3Decoder(bytes);
      decoder.decodeSync(); // 결과는 사용하지 않으므로 변수에 할당하지 않음

      // ID3v2.3.0 미만인 경우 업그레이드
      bool needsUpgrade = false;
      final headerBytes = await file.openRead(0, 5).toList();
      if (headerBytes.isNotEmpty &&
          headerBytes[0].length >= 5 &&
          String.fromCharCodes(headerBytes[0].sublist(0, 3)) == 'ID3') {
        final major = headerBytes[0][3];
        // final minor = headerBytes[0][4];
        if (major < 3) {
          needsUpgrade = true;
        }
      }

      if (needsUpgrade) {
        await _upgradeToID3v2_3(filePath, metadata);
      }

      return {
        'title': metadata.songName ?? 'Unknown Title',
        'artist': metadata.leadPerformer ?? 'Unknown Artist',
        'album': metadata.album ?? 'Unknown Album',
        'duration': metadata.duration ?? 0,
        'year': metadata.year ?? '',
        'genre': metadata.contentType ?? '',
        'trackNumber': metadata.trackNumber ?? 0,
        'filePath': filePath,
      };
    } catch (e) {
      // print('Error reading metadata: $e');
      return {
        'title': 'Unknown Title',
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': 0,
        'year': '',
        'genre': '',
        'trackNumber': 0,
        'filePath': filePath,
      };
    }
  }

  static Future<void> _upgradeToID3v2_3(
      String filePath, Mp3Metadata metadata) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final encoder = ID3Encoder(bytes);

      // ID3v2.3 형식으로 메타데이터 변환
      final v2_3Metadata = MetadataV2p3Body(
        title: metadata.songName,
        artist: metadata.leadPerformer,
        album: metadata.album,
        // 추가 메타데이터는 userDefines에 저장
        userDefines: {
          'year': metadata.year?.toString() ?? '',
          'genre': metadata.contentType?.toString() ?? '',
          'trackNumber': metadata.trackNumber?.toString() ?? '',
        },
      );

      // 새로운 ID3v2.3 태그로 인코딩
      final resultBytes = encoder.encodeSync(v2_3Metadata);

      // 파일에 저장
      await file.writeAsBytes(resultBytes);
      // print('Successfully upgraded ID3 tag to v2.3 for: $filePath');
    } catch (e) {
      // print('Error upgrading ID3 tag: $e');
    }
  }

  int? parseDurationString(String? value) {
    if (value == null) return null;
    final parts = value.split(':').map((e) => int.tryParse(e)).toList();
    if (parts.contains(null)) return null;
    if (parts.length == 3) {
      // hh:mm:ss
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    } else if (parts.length == 2) {
      // mm:ss
      return parts[0]! * 60 + parts[1]!;
    } else if (parts.length == 1) {
      return parts[0];
    }
    return null;
  }
}
