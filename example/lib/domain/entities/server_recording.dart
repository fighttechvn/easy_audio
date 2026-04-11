class ServerRecording {
  const ServerRecording({
    required this.source,
    required this.createdAt,
    required this.fileSizeBytes,
  });

  final String source;
  final DateTime createdAt;
  final int fileSizeBytes;
}
