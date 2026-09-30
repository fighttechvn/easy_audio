part of 'record_session_cubit.dart';

@immutable
class RecordSessionState {
  const RecordSessionState({
    this.session,
    this.minimized = false,
    this.sheetOpen = false,
    this.audioState = EasyAudioState.idle,
    this.pendingRecordingId,
    this.elapsed = Duration.zero,
    this.openSheetRequestId = 0,
    this.maxSamples = 60,
    this.lastUploadedDataId,
    this.lastUploadSuccess,
    this.lastUploadAt,
    this.lastSavedRecordingId,
    this.lastSavedAt,
    this.lastSavedFilePath,
    this.lastSavedDataId,
    this.lastSavedContent,
  });

  final RecordSession? session;
  final bool minimized;
  final bool sheetOpen;
  final EasyAudioState audioState;
  final String? pendingRecordingId;
  final Duration elapsed;
  final int openSheetRequestId;
  final int maxSamples;

  final String? lastUploadedDataId;
  final bool? lastUploadSuccess;
  final DateTime? lastUploadAt;
  final String? lastSavedRecordingId;
  final DateTime? lastSavedAt;
  final String? lastSavedFilePath;
  final String? lastSavedDataId;
  final String? lastSavedContent;

  bool get hasSession => session != null;

  bool get isIdle => audioState == EasyAudioState.idle;

  bool get canReopen => session != null && !isIdle;

  bool get isRecording => audioState == EasyAudioState.recording;

  RecordSessionState copyWith({
    RecordSession? session,
    bool? minimized,
    bool? sheetOpen,
    EasyAudioState? audioState,
    String? pendingRecordingId,
    Duration? elapsed,
    int? openSheetRequestId,
    int? maxSamples,
    String? lastUploadedDataId,
    bool? lastUploadSuccess,
    DateTime? lastUploadAt,
    String? lastSavedRecordingId,
    DateTime? lastSavedAt,
    String? lastSavedFilePath,
    String? lastSavedDataId,
    String? lastSavedContent,
  }) {
    return RecordSessionState(
      session: session ?? this.session,
      minimized: minimized ?? this.minimized,
      sheetOpen: sheetOpen ?? this.sheetOpen,
      audioState: audioState ?? this.audioState,
      pendingRecordingId: pendingRecordingId ?? this.pendingRecordingId,
      elapsed: elapsed ?? this.elapsed,
      openSheetRequestId: openSheetRequestId ?? this.openSheetRequestId,
      maxSamples: maxSamples ?? this.maxSamples,
      lastUploadedDataId: lastUploadedDataId ?? this.lastUploadedDataId,
      lastUploadSuccess: lastUploadSuccess ?? this.lastUploadSuccess,
      lastUploadAt: lastUploadAt ?? this.lastUploadAt,
      lastSavedRecordingId: lastSavedRecordingId ?? this.lastSavedRecordingId,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      lastSavedFilePath: lastSavedFilePath ?? this.lastSavedFilePath,
      lastSavedDataId: lastSavedDataId ?? this.lastSavedDataId,
      lastSavedContent: lastSavedContent ?? this.lastSavedContent,
    );
  }
}
