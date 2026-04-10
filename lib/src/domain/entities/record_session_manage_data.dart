import 'easy_audio_state.dart';
import 'record_session.dart';

class RecordSessionManageData {
  final List<double> amplitudeHistory;
  final int maxSamples;
  final EasyAudioState state;
  final String finalTranscript;
  final String liveTranscript;

  final RecordSession? session;
  final bool minimized;
  final bool sheetOpen;

  final String? pendingRecordingId;

  final String? lastUploadedContextId;
  final bool? lastUploadSuccess;
  final DateTime? lastUploadAt;

  RecordSessionManageData({
    List<double> amplitudeHistory = const <double>[],
    this.maxSamples = 60,
    this.state = EasyAudioState.idle,
    this.finalTranscript = '',
    this.liveTranscript = '',
    this.session,
    this.minimized = false,
    this.sheetOpen = false,
    this.pendingRecordingId,
    this.lastUploadedContextId,
    this.lastUploadSuccess,
    this.lastUploadAt,
  }) : amplitudeHistory = List<double>.unmodifiable(amplitudeHistory);

  RecordSessionManageData copyWith({
    List<double>? amplitudeHistory,
    RecordSession? session,
    String? pendingRecordingId,
    String? lastUploadedContextId,
    bool? lastUploadSuccess,
    DateTime? lastUploadAt,
    bool? minimized,
    EasyAudioState? state,
    bool? sheetOpen,
    String? finalTranscript,
    String? liveTranscript,
    int? maxSamples,
  }) {
    return RecordSessionManageData(
      amplitudeHistory: amplitudeHistory ?? this.amplitudeHistory,
      session: session ?? this.session,
      pendingRecordingId: pendingRecordingId ?? this.pendingRecordingId,
      lastUploadedContextId:
          lastUploadedContextId ?? this.lastUploadedContextId,
      lastUploadSuccess: lastUploadSuccess ?? this.lastUploadSuccess,
      lastUploadAt: lastUploadAt ?? this.lastUploadAt,
      minimized: minimized ?? this.minimized,
      state: state ?? this.state,
      sheetOpen: sheetOpen ?? this.sheetOpen,
      finalTranscript: finalTranscript ?? this.finalTranscript,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      maxSamples: maxSamples ?? this.maxSamples,
    );
  }

  RecordSessionManageData resetSession() {
    return RecordSessionManageData(
      amplitudeHistory: amplitudeHistory,
      session: null,
      pendingRecordingId: null,
      minimized: false,
      sheetOpen: false,
      lastUploadedContextId: lastUploadedContextId,
      lastUploadSuccess: lastUploadSuccess,
      lastUploadAt: lastUploadAt,
      state: state,
      finalTranscript: finalTranscript,
      liveTranscript: liveTranscript,
      maxSamples: maxSamples,
    );
  }
}
