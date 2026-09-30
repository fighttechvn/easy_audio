import 'dart:io';
import 'dart:typed_data';

import 'package:easy_audio/src/core/utils/wav_duration.dart';
import 'package:flutter_test/flutter_test.dart';

/// 16 kHz mono PCM16 => 32000 bytes per second.
const _sampleRate = 16000;
const _channels = 1;
const _bitsPerSample = 16;
const _byteRate = _sampleRate * _channels * _bitsPerSample ~/ 8;

Uint8List _buildWav({
  required int dataSize,
  int? declaredDataSize,
  List<int> extraChunk = const [],
  String riffTag = 'RIFF',
  String waveTag = 'WAVE',
}) {
  final bytes = BytesBuilder();
  void ascii(String s) => bytes.add(s.codeUnits);
  void u32(int v) =>
      bytes.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) =>
      bytes.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());

  ascii(riffTag);
  u32(36 + dataSize + extraChunk.length);
  ascii(waveTag);

  ascii('fmt ');
  u32(16);
  u16(1); // PCM
  u16(_channels);
  u32(_sampleRate);
  u32(_byteRate);
  u16(_channels * _bitsPerSample ~/ 8);
  u16(_bitsPerSample);

  bytes.add(extraChunk);

  ascii('data');
  u32(declaredDataSize ?? dataSize);
  bytes.add(Uint8List(dataSize));

  return bytes.toBytes();
}

/// A chunk with an odd payload length, which the spec pads to an even boundary.
List<int> _oddListChunk() {
  final bytes = BytesBuilder();
  bytes.add('LIST'.codeUnits);
  bytes.add((ByteData(4)..setUint32(0, 3, Endian.little)).buffer.asUint8List());
  bytes.add([1, 2, 3]); // payload
  bytes.add([0]); // pad byte
  return bytes.toBytes();
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('wav_duration_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<String> write(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  test('reads the duration of a well-formed file', () async {
    final path = await write('one_second.wav', _buildWav(dataSize: _byteRate));
    expect(await WavDuration.read(path), const Duration(seconds: 1));
  });

  test('computes sub-second durations', () async {
    final path = await write('half.wav', _buildWav(dataSize: _byteRate ~/ 2));
    expect(await WavDuration.read(path), const Duration(milliseconds: 500));
  });

  test('falls back to the on-disk size when data size is left at zero',
      () async {
    // What a recording killed mid-write leaves behind.
    final path = await write(
      'unfinished.wav',
      _buildWav(dataSize: _byteRate * 2, declaredDataSize: 0),
    );
    expect(await WavDuration.read(path), const Duration(seconds: 2));
  });

  test('clamps a data size that overruns the file', () async {
    final path = await write(
      'overrun.wav',
      _buildWav(dataSize: _byteRate, declaredDataSize: _byteRate * 99),
    );
    expect(await WavDuration.read(path), const Duration(seconds: 1));
  });

  test('skips intermediate chunks, honouring the odd-size pad byte', () async {
    final path = await write(
      'with_list.wav',
      _buildWav(dataSize: _byteRate, extraChunk: _oddListChunk()),
    );
    expect(await WavDuration.read(path), const Duration(seconds: 1));
  });

  test('returns null for a non-RIFF file', () async {
    final path = await write(
      'not_riff.wav',
      _buildWav(dataSize: _byteRate, riffTag: 'JUNK'),
    );
    expect(await WavDuration.read(path), isNull);
  });

  test('returns null when the RIFF form is not WAVE', () async {
    final path = await write(
      'not_wave.wav',
      _buildWav(dataSize: _byteRate, waveTag: 'AVI '),
    );
    expect(await WavDuration.read(path), isNull);
  });

  test('returns null for a header-only file with no audio', () async {
    final path = await write('empty.wav', _buildWav(dataSize: 0));
    expect(await WavDuration.read(path), isNull);
  });

  test('returns null for a truncated file', () async {
    final path = await write('tiny.wav', 'RIFF'.codeUnits);
    expect(await WavDuration.read(path), isNull);
  });

  test('returns null when the file does not exist', () async {
    expect(await WavDuration.read('${tmp.path}/nope.wav'), isNull);
  });
}
