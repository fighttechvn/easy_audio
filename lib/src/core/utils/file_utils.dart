import 'dart:io';

class FileUtils {
  FileUtils._();

  static Future<int?> safeLength(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file.length();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> safeDelete(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return;
    }
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // ignore
    }
  }
}
