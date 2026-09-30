import 'package:flutter/foundation.dart';

import '../../../domain/entities/pending_recording.dart';

enum RecordAudioToastType { success, warning, error }

@immutable
class CrashRecoveryEffect {
  const CrashRecoveryEffect._({
    required this.type,
    this.record,
    this.languageDisplayName,
    this.message,
    this.toastType,
  });

  factory CrashRecoveryEffect.showUnfinishedRecording({
    required PendingRecording record,
    required String languageDisplayName,
  }) {
    return CrashRecoveryEffect._(
      type: CrashRecoveryEffectType.showUnfinishedRecording,
      record: record,
      languageDisplayName: languageDisplayName,
    );
  }

  factory CrashRecoveryEffect.showToast({
    required String message,
    required RecordAudioToastType type,
  }) {
    return CrashRecoveryEffect._(
      type: CrashRecoveryEffectType.showToast,
      message: message,
      toastType: type,
    );
  }

  final CrashRecoveryEffectType type;
  final PendingRecording? record;
  final String? languageDisplayName;
  final String? message;
  final RecordAudioToastType? toastType;
}

enum CrashRecoveryEffectType { showUnfinishedRecording, showToast }
