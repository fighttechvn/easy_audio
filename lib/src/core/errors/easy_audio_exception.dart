// ignore_for_file: lines_longer_than_80_chars

class EasyAudioException implements Exception {
  final String code;

  final String message;

  final dynamic originalError;

  final StackTrace? stackTrace;

  const EasyAudioException({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  factory EasyAudioException.microphonePermissionDenied() =>
      const EasyAudioException(
        code: 'MICROPHONE_PERMISSION_DENIED',
        message:
            'Microphone permission was denied. Please enable it in settings.',
      );

  factory EasyAudioException.speechPermissionDenied() => const EasyAudioException(
    code: 'SPEECH_PERMISSION_DENIED',
    message:
        'Speech recognition permission was denied. Please enable it in settings.',
  );

  factory EasyAudioException.notInitialized() => const EasyAudioException(
    code: 'NOT_INITIALIZED',
    message: 'EasyAudioService is not initialized. Call initialize() first.',
  );

  factory EasyAudioException.alreadyRecording() => const EasyAudioException(
    code: 'ALREADY_RECORDING',
    message: 'Recording is already in progress.',
  );

  factory EasyAudioException.notRecording() => const EasyAudioException(
    code: 'NOT_RECORDING',
    message: 'No recording in progress.',
  );

  factory EasyAudioException.realtimeNotSupported() => const EasyAudioException(
    code: 'REALTIME_NOT_SUPPORTED',
    message: 'Realtime mode is only supported on iOS.',
  );

  factory EasyAudioException.speechNotAvailable() => const EasyAudioException(
    code: 'SPEECH_NOT_AVAILABLE',
    message: 'Speech recognition is not available on this device.',
  );

  factory EasyAudioException.unknown(dynamic error, [StackTrace? stackTrace]) =>
      EasyAudioException(
        code: 'UNKNOWN_ERROR',
        message: error?.toString() ?? 'An unknown error occurred.',
        originalError: error,
        stackTrace: stackTrace,
      );

  @override
  String toString() => 'EasyAudioException[$code]: $message';
}
