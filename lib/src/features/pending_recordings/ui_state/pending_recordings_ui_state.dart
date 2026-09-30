import 'package:flutter/foundation.dart';

import '../../../domain/entities/pending_recording.dart';

@immutable
class PendingRecordingsUiState {
  const PendingRecordingsUiState({this.items = const <PendingRecording>[]});

  final List<PendingRecording> items;

  PendingRecordingsUiState copyWith({List<PendingRecording>? items}) {
    return PendingRecordingsUiState(items: items ?? this.items);
  }
}
