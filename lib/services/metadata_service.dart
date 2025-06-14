import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:id3_codec/id3_codec.dart';
import '../models/song.dart';

class MetadataService {
  Future<List<Song>> getSongsFromDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<Song> songs = [];

    try {
      final files = await directory
          .list()
          .where((entity) => entity.path.toLowerCase().endsWith('.mp3'))
          .toList();

      for (var file in files) {
        try {
          final parserTag = readAllMetadata(File(file.path));
          if (parserTag is Mp3Metadata) {
            print('==== ${file.path} ====');
            print(parserTag);
            print('--------------------------');

            final artist = (parserTag.bandOrOrchestra ??
                    parserTag.leadPerformer ??
                    parserTag.conductor ??
                    'Unknown Artist')
                .trim();
            final title = (parserTag.songName ??
                    parserTag.subtitle ??
                    parserTag.contentGroupDescription ??
                    'Unknown Title')
                .trim();

            Uint8List? albumArt;
            if (parserTag.pictures.isNotEmpty) {
              print(parserTag.pictures.first);
              // Picture 객체의 실제 데이터 필드명 확인 필요. 일반적으로 'data' 또는 'imageData' 등일 수 있음.
              albumArt = parserTag.pictures.first.bytes;
            }

            String? bpmStr;
            if (parserTag.bpm is Duration) {
              bpmStr = null;
            } else {
              bpmStr = parserTag.bpm?.toString();
            }
            int? yearVal;
            if (parserTag.year is Duration) {
              yearVal = null;
            } else if (parserTag.year is int) {
              yearVal = parserTag.year;
            } else {
              yearVal = int.tryParse(parserTag.year?.toString() ?? '');
            }
            String? genreStr;
            if (parserTag.contentType is Duration) {
              genreStr = null;
            } else {
              genreStr = parserTag.contentType?.toString();
            }
            int? duration;
            if (parserTag.duration is int) {
              duration = parserTag.duration as int;
            } else if (parserTag.duration is String) {
              duration = parseDurationString(parserTag.duration as String);
            } else if (parserTag.duration is Duration) {
              duration = (parserTag.duration as Duration).inSeconds;
            } else {
              duration = null;
            }
            songs.add(Song(
              filePath: file.path,
              artist: artist,
              title: title,
              bpm: int.tryParse(bpmStr ?? ''),
              year: yearVal,
              genre: genreStr,
              albumArt: albumArt,
              duration: duration,
            ));
          }
        } catch (e) {
          print('Error reading metadata for ${file.path}: $e');
          // 메타데이터를 읽을 수 없는 경우에도 기본 정보만 포함
          songs.add(Song(filePath: file.path));
        }
      }
    } catch (e) {
      print('Error reading directory: $e');
      rethrow;
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
      final id3Metadata = decoder.decodeSync();

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
      print('Error reading metadata: $e');
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
      print('Successfully upgraded ID3 tag to v2.3 for: $filePath');
    } catch (e) {
      print('Error upgrading ID3 tag: $e');
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
