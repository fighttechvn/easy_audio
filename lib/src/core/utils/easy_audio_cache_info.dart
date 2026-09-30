import 'dart:io';

import '../../domain/entities/easy_audio_config.dart';
import 'easy_audio_paths.dart';

class EasyAudioCacheInfo {
  EasyAudioCacheInfo._();

  static Future<void> save({
    required EasyAudioConfig config,
    required DateTime? recordingStartTime,
    required String cachePath,
    required String targetPath,
  }) async {
    final infoFile = await EasyAudioPaths.cacheInfoFile();
    final localeId = (config.locale ?? '').trim();
    await infoFile.writeAsString(
      '$cachePath\n$targetPath'
      '\n${recordingStartTime?.toIso8601String()}'
      '${localeId.isEmpty ? '' : '\n$localeId'}',
    );
  }

  static Future<void> clear() async {
    final infoFile = await EasyAudioPaths.cacheInfoFile();
    if (await infoFile.exists()) {
      await infoFile.delete();
    }
  }

  static Future<List<String>?> readLinesIfExists() async {
    final infoFile = await EasyAudioPaths.cacheInfoFile();
    if (!await infoFile.exists()) {
      return null;
    }
    final content = await infoFile.readAsString();
    return content.split('\n');
  }

  static Future<void> deleteInfoFileIfExists() async {
    final infoFile = await EasyAudioPaths.cacheInfoFile();
    if (await infoFile.exists()) {
      await infoFile.delete();
    }
  }

  static Future<File> infoFile() => EasyAudioPaths.cacheInfoFile();
}
