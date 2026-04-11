import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/easy_audio_config.dart';

class EasyAudioPaths {
  EasyAudioPaths._();

  static Future<String> generateFilePath(EasyAudioConfig config) async {
    final directory = config.outputDirectory ??
        (await getApplicationDocumentsDirectory()).path;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = config.resolvedFileExtension;
    return '$directory/${config.filePrefix}$timestamp.$extension';
  }

  static Future<File> cacheInfoFile() async {
    final cacheDir = await getTemporaryDirectory();
    return File('${cacheDir.path}/easy_audio_cache_info.txt');
  }
}
