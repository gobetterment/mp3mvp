import 'dart:io';
import 'dart:typed_data';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
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
            print('songName: \\${parserTag.songName}');
            print('subtitle: \\${parserTag.subtitle}');
            print(
                'contentGroupDescription: \\${parserTag.contentGroupDescription}');
            print('bandOrOrchestra: \\${parserTag.bandOrOrchestra}');
            print('leadPerformer: \\${parserTag.leadPerformer}');
            print('conductor: \\${parserTag.conductor}');
            print('bpm: \\${parserTag.bpm}');
            print('year: \\${parserTag.year}');
            print('contentType: \\${parserTag.contentType}');
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

            songs.add(Song(
              filePath: file.path,
              artist: artist,
              title: title,
              bpm: int.tryParse(parserTag.bpm ?? ''),
              year: parserTag.year,
              genre: parserTag.contentType,
              albumArt: albumArt,
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
}
