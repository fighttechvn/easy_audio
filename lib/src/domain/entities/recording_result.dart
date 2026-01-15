import '../../core/utils/duration_format.dart';

class RecordingResult {
  final String? filePath;
  final Duration duration;
  final String? transcript;
  final bool wasRecovered;
  final DateTime startTime;
  final DateTime endTime;
  final int? fileSizeBytes;
  final String? localeId;

  const RecordingResult({
    this.filePath,
    required this.duration,
    this.transcript,
    this.wasRecovered = false,
    required this.startTime,
    required this.endTime,
    this.fileSizeBytes,
    this.localeId,
  });

  bool get hasFile => filePath != null;

  bool get hasTranscript => transcript != null && transcript!.isNotEmpty;

  String get formattedDuration => formatDuration(duration);

  String? get formattedFileSize {
    if (fileSizeBytes == null) {
      return null;
    }
    if (fileSizeBytes! < 1024) {
      return '${fileSizeBytes}B';
    }
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  String toString() {
    return 'RecordingResult(duration: $formattedDuration, '
        'hasFile: $hasFile, hasTranscript: $hasTranscript, '
        'wasRecovered: $wasRecovered, localeId: $localeId)';
  }
}
