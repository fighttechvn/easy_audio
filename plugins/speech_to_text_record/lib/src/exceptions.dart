/// Thrown when microphone permission is missing.
class MicrophonePermissionException implements Exception {
  MicrophonePermissionException([this.message]);

  final String? message;

  @override
  String toString() =>
      'MicrophonePermissionException: ${message ?? 'Microphone permission not granted'}';
}

/// Thrown when audio recording lifecycle is misused.
class AudioPipelineStateException implements Exception {
  AudioPipelineStateException(this.message);

  final String message;

  @override
  String toString() => 'AudioPipelineStateException: $message';
}

/// Raised when no speech recognition backend is available.
class SpeechToTextNotSupportedException implements Exception {
  SpeechToTextNotSupportedException([
    this.message = 'Speech-to-text is not supported on this platform',
  ]);

  final String message;

  @override
  String toString() => 'SpeechToTextNotSupportedException: $message';
}
