class RecordData {
  final String url;
  final String? id;
  final String? title;
  final Duration totalTime;
  final DateTime createdAt;
  final String? content;

  const RecordData({
    this.content,
    required this.url,
    this.id,
    this.title,
    required this.totalTime,
    required this.createdAt,
  });
}
