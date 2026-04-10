/// Generic record wrapper for carrying host app data through easy_audio.
///
/// IMPORTANT: [id] must be stable across app restarts because easy_audio
/// uses it for grouping/filtering pending recordings and for UI refresh.
class DataRecord<T> {
  const DataRecord({required this.id, required this.data});

  final String id;
  final T data;
}
