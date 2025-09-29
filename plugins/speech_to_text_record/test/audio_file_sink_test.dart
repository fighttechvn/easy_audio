import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

void main() {
  group('AudioFileSink', () {
    late StreamController<Uint8List> controller;
    late AudioFileSink sink;

    setUp(() {
      controller = StreamController<Uint8List>.broadcast();
      sink = AudioFileSink(stream: controller.stream, sampleRate: 16000);
    });

    tearDown(() async {
      await sink.dispose();
      await controller.close();
    });

    test('writes WAV header and payload', () async {
      final directory = await Directory.systemTemp.createTemp('wav_sink');
      final filePath = defaultRecordingPath(
        directory.path,
        fileName: 'sample.wav',
      );

      await sink.start(filePath);
      controller.add(
        Uint8List.fromList(List<int>.generate(320, (int index) => index % 256)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final savedPath = await sink.stop();
      expect(savedPath, filePath);

      final output = File(filePath);
      expect(await output.exists(), isTrue);
      final bytes = await output.readAsBytes();
      expect(bytes.length, 44 + 320);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');

      await directory.delete(recursive: true);
    });
  });
}
