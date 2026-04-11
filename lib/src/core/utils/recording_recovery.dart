import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/recording_result.dart';
import 'easy_audio_cache_info.dart';
import 'wav_header_repair.dart';

class RecordingRecovery {
  RecordingRecovery._();

  static Future<RecordingResult?> recoverLastRecording() async {
    final lines = await EasyAudioCacheInfo.readLinesIfExists();
    if (lines == null || lines.length < 2) {
      return null;
    }

    final cachePath = lines[0];
    final targetPath = lines[1];
    final startTimeStr = lines.length > 2 ? lines[2] : null;
    final localeId = lines.length > 3 ? lines[3].trim() : null;

    final cacheFile = File(cachePath);
    if (!await cacheFile.exists()) {
      await EasyAudioCacheInfo.deleteInfoFileIfExists();
      return null;
    }

    try {
      int fileSize;
      if (cachePath == targetPath) {
        fileSize = await cacheFile.length();
        await EasyAudioCacheInfo.deleteInfoFileIfExists();
      } else {
        await cacheFile.copy(targetPath);
        fileSize = await cacheFile.length();
        await cacheFile.delete();
        await EasyAudioCacheInfo.deleteInfoFileIfExists();
      }

      if (fileSize <= 0) {
        return null;
      }

      await WavHeaderRepair.tryRepairIfNeeded(targetPath);

      Duration duration = Duration.zero;
      final player = AudioPlayer();
      try {
        duration = (await player.setFilePath(targetPath)) ?? Duration.zero;
      } catch (_) {
        duration = Duration.zero;
      } finally {
        await player.dispose();
      }

      final startTime = startTimeStr != null
          ? DateTime.tryParse(startTimeStr) ?? DateTime.now()
          : DateTime.now();

      return RecordingResult(
        filePath: targetPath,
        duration: duration,
        transcript: null,
        wasRecovered: true,
        startTime: startTime,
        endTime: DateTime.now(),
        fileSizeBytes: fileSize,
        localeId: (localeId != null && localeId.isNotEmpty) ? localeId : null,
      );
    } catch (e) {
      debugPrint('Failed to recover recording: $e');
      return null;
    }
  }
}
