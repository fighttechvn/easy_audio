import 'dart:io';
import 'dart:typed_data';

/// Reads the playback duration of a PCM WAV file directly from its header.
///
/// SttRecord always writes WAV/PCM16, so the duration is derivable without
/// decoding. This matters because `just_audio_background` routes every
/// `AudioPlayer` through a single global audio handler: a throwaway player
/// built just to probe a duration would hijack — and on dispose, stop —
/// whatever is currently playing.
class WavDuration {
  WavDuration._();

  static const _riffHeaderLength = 12;
  static const _chunkHeaderLength = 8;
  static const _fmtChunkMinLength = 16;

  /// Returns null when [filePath] is missing, not a RIFF/WAVE file, or its
  /// header is too damaged to interpret.
  static Future<Duration?> read(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    RandomAccessFile? raf;
    try {
      final length = await file.length();
      if (length < _riffHeaderLength + _chunkHeaderLength) {
        return null;
      }

      raf = await file.open(mode: FileMode.read);

      final riff = await raf.read(_riffHeaderLength);
      if (riff.length < _riffHeaderLength) {
        return null;
      }
      if (String.fromCharCodes(riff.sublist(0, 4)) != 'RIFF' ||
          String.fromCharCodes(riff.sublist(8, 12)) != 'WAVE') {
        return null;
      }

      var byteRate = 0;
      var offset = _riffHeaderLength;

      while (offset + _chunkHeaderLength <= length) {
        await raf.setPosition(offset);
        final header = await raf.read(_chunkHeaderLength);
        if (header.length < _chunkHeaderLength) {
          return null;
        }

        final id = String.fromCharCodes(header.sublist(0, 4));
        final declaredSize = ByteData.sublistView(
          header,
        ).getUint32(4, Endian.little);
        final payloadOffset = offset + _chunkHeaderLength;

        if (id == 'fmt ') {
          if (declaredSize < _fmtChunkMinLength) {
            return null;
          }
          final fmt = await raf.read(_fmtChunkMinLength);
          if (fmt.length < _fmtChunkMinLength) {
            return null;
          }
          byteRate = ByteData.sublistView(fmt).getUint32(8, Endian.little);
        } else if (id == 'data') {
          if (byteRate <= 0) {
            return null;
          }
          // A recording killed mid-write leaves a stale (often zero, sometimes
          // oversized) size field, so trust what is actually on disk.
          final onDisk = length - payloadOffset;
          final dataSize = (declaredSize == 0 || declaredSize > onDisk)
              ? onDisk
              : declaredSize;
          if (dataSize <= 0) {
            return null;
          }
          return Duration(
            microseconds: (dataSize * Duration.microsecondsPerSecond) ~/
                byteRate,
          );
        }

        // Chunks are word-aligned: an odd size is followed by a pad byte.
        final advance = declaredSize + (declaredSize.isOdd ? 1 : 0);
        if (advance <= 0) {
          return null;
        }
        offset = payloadOffset + advance;
      }

      return null;
    } catch (_) {
      return null;
    } finally {
      try {
        await raf?.close();
      } catch (_) {}
    }
  }
}
