class AudioPlaybackSnapshot {
  const AudioPlaybackSnapshot({
    required this.currentUrl,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
  });

  final String? currentUrl;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration? duration;

  AudioPlaybackSnapshot copyWith({
    String? currentUrl,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    bool clearUrl = false,
    bool clearDuration = false,
  }) {
    return AudioPlaybackSnapshot(
      currentUrl: clearUrl ? null : (currentUrl ?? this.currentUrl),
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: clearDuration ? null : (duration ?? this.duration),
    );
  }

  static const empty = AudioPlaybackSnapshot(
    currentUrl: null,
    isPlaying: false,
    isLoading: false,
    position: Duration.zero,
    duration: null,
  );
}
