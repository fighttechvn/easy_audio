import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class WavHeaderRepair {
  WavHeaderRepair._();

  static Future<void> tryRepairIfNeeded(String filePath) async {
    final lower = filePath.toLowerCase();
    if (!lower.endsWith('.wav')) {
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    final length = await file.length();
    if (length < 44) {
      return;
    }

    RandomAccessFile? rafRead;
    RandomAccessFile? rafWrite;
    try {
      final headerLen = min(4096, length);

      rafRead = await file.open(mode: FileMode.read);
      await rafRead.setPosition(0);
      final header = await rafRead.read(headerLen);
      if (header.length < 12) {
        return;
      }

      if (String.fromCharCodes(header.sublist(0, 4)) != 'RIFF') {
        return;
      }
      if (String.fromCharCodes(header.sublist(8, 12)) != 'WAVE') {
        return;
      }

      int dataIndex = -1;
      for (var i = 12; i <= header.length - 8; i++) {
        if (header[i] == 0x64 &&
            header[i + 1] == 0x61 &&
            header[i + 2] == 0x74 &&
            header[i + 3] == 0x61) {
          dataIndex = i;
          break;
        }
      }
      if (dataIndex < 0) {
        return;
      }

      final riffSize = length - 8;
      final dataSize = length - (dataIndex + 8);
      if (riffSize <= 0 || dataSize <= 0) {
        return;
      }

      final riffSizeBytes = ByteData(4)..setUint32(0, riffSize, Endian.little);
      final dataSizeBytes = ByteData(4)..setUint32(0, dataSize, Endian.little);

      rafWrite = await file.open(mode: FileMode.append);

      await rafWrite.setPosition(4);
      await rafWrite.writeFrom(riffSizeBytes.buffer.asUint8List());

      await rafWrite.setPosition(dataIndex + 4);
      await rafWrite.writeFrom(dataSizeBytes.buffer.asUint8List());
    } catch (_) {
      // Best-effort.
    } finally {
      try {
        await rafRead?.close();
      } catch (_) {}
      try {
        await rafWrite?.close();
      } catch (_) {}
    }
  }
}
