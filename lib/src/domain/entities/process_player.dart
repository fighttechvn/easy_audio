class ProcessPlayer {
  final Duration? duration;
  final Duration? position;

  const ProcessPlayer({
    this.duration,
    this.position,
  });

  ProcessPlayer copyWith({
    Duration? duration,
    Duration? position,
  }) {
    return ProcessPlayer(
      duration: duration ?? this.duration,
      position: position ?? this.position,
    );
  }
}
