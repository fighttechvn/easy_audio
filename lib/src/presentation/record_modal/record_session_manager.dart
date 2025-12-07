import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/utils/logs/debug_print/record_session_manager_log.dart';
import 'bloc/speech_text_bloc.dart';

/// Singleton manager để quản lý recording session state
/// Cho phép share state giữa modal và floating widget
class RecordSessionManager<T> {
  RecordSessionManager._();

  static final RecordSessionManager instance = RecordSessionManager._();

  // Session data
  SpeechTextBloc? _bloc;
  T? _data;
  String? _content;
  DateTime? _recordStartedAt;
  Duration _pausedAccumulated = Duration.zero;
  DateTime? _pausedAt;
  bool _isMinimized = false;
  String? _locale;
  String? _title;
  Future<bool?> Function(BuildContext)? _onExit;

  // Pipeline state management
  void Function(String)? _updateContentCallback;
  bool _isPipelineActive = false;

  // Callbacks for UI updates
  final StreamController<bool> _minimizedStateController =
      StreamController<bool>.broadcast();

  // Getters
  SpeechTextBloc? get bloc => _bloc;
  String? get content => _content;
  DateTime? get recordStartedAt => _recordStartedAt;
  Duration get pausedAccumulated => _pausedAccumulated;
  DateTime? get pausedAt => _pausedAt;
  bool get isMinimized => _isMinimized;
  bool get hasActiveSession => _bloc != null;
  String? get locale => _locale;
  String? get title => _title;
  Future<bool?> Function(BuildContext context)? get onExit => _onExit;
  T? get data => _data;
  Stream<bool> get minimizedStateStream => _minimizedStateController.stream;
  void Function(String)? get updateContentCallback => _updateContentCallback;
  bool get isPipelineActive => _isPipelineActive;

  /// Khởi tạo session mới
  void startSession({
    required SpeechTextBloc bloc,
    required String locale,
    String? title,
    Future<bool?> Function(BuildContext)? onExit,
  }) {
    debugPrintStartingNewSession(locale, title != null);
    _bloc = bloc;
    _recordStartedAt = DateTime.now();
    _pausedAccumulated = Duration.zero;
    _pausedAt = null;
    _isMinimized = false;
    _locale = locale;
    _title = title;
    _onExit = onExit;
    // Reset pipeline state for new session
    _updateContentCallback = null;
    _isPipelineActive = false;
    debugPrintSessionStartedSuccessfully();
  }

  /// Cập nhật recording metadata
  void updateRecordingMetadata({
    DateTime? recordStartedAt,
    Duration? pausedAccumulated,
    DateTime? pausedAt,
  }) {
    if (recordStartedAt != null) {
      _recordStartedAt = recordStartedAt;
    }
    if (pausedAccumulated != null) {
      _pausedAccumulated = pausedAccumulated;
    }
    if (pausedAt != null) {
      _pausedAt = pausedAt;
    }
  }

  // ignore: use_setters_to_change_properties
  void updateData(T? data) {
    _data = data;
  }

  /// Chuyển sang floating mode
  void minimizeSession() {
    if (!hasActiveSession) {
      debugPrintWarningMinimizeSessionNoActiveSession();
      return;
    }
    debugPrintMinimizingSession(
      _isPipelineActive,
      _updateContentCallback != null,
      _content?.length ?? 0,
    );
    _isMinimized = true;
    _minimizedStateController.add(true);
    debugPrintSessionMinimizedEmitted();
  }

  /// Restore lại modal từ floating
  void restoreSession() {
    if (!hasActiveSession) {
      debugPrintWarningRestoreSessionNoActiveSession();
      return;
    }
    debugPrintRestoringSession(
      _isPipelineActive,
      _updateContentCallback != null,
      _content?.length ?? 0,
      _bloc?.state.runtimeType,
    );
    _isMinimized = false;
    _minimizedStateController.add(false);
    debugPrintSessionRestoredEmitted();
  }

  /// Set callback để update content từ speech-to-text
  void setUpdateContentCallback(void Function(String)? callback) {
    final wasSet = _updateContentCallback != null;
    _updateContentCallback = callback;
    final isSet = callback != null;
    debugPrintUpdateContentCallbackChanged(wasSet, isSet);
  }

  /// Set trạng thái pipeline active/inactive
  void setPipelineActive(bool active) {
    final wasActive = _isPipelineActive;
    _isPipelineActive = active;
    debugPrintPipelineStateChanged(
      wasActive,
      active,
      _updateContentCallback != null,
    );
  }

  /// Restart pipeline nếu cần khi restore session
  void restartPipelineIfNeeded(SpeechTextBloc bloc) {
    debugPrintCheckingPipelineRestartNeeded(
      _isPipelineActive,
      _updateContentCallback != null,
      bloc.isClosed,
    );

    if (!_isPipelineActive && _updateContentCallback != null) {
      if (!bloc.isClosed) {
        debugPrintRestartingPipelineWithSavedCallback();
        bloc.add(StartRecordEvent(callbackToText: _updateContentCallback!));
        _isPipelineActive = true;
        debugPrintPipelineRestartedSuccessfully();
      } else {
        debugPrintCannotRestartPipelineBlocClosed();
      }
    } else {
      debugPrintPipelineRestartNotNeeded();
    }
  }

  /// Kết thúc session và cleanup
  void endSession({bool disposeResources = true}) {
    debugPrintEndingSession(
      disposeResources,
      hasActiveSession,
      _isPipelineActive,
    );

    // Dispose bloc và controller nếu cần
    if (disposeResources) {
      if (_bloc != null && !_bloc!.isClosed) {
        debugPrintClosingBloc();
        _bloc?.close();
      }
      _content = null;
    }

    // Clear references
    _bloc = null;
    _content = null;
    _recordStartedAt = null;
    _pausedAccumulated = Duration.zero;
    _pausedAt = null;
    _isMinimized = false;
    _locale = null;
    _title = null;
    _onExit = null;
    _minimizedStateController.add(false);

    // Clear pipeline state
    _updateContentCallback = null;
    _isPipelineActive = false;

    debugPrintSessionEndedAndCleanedUp();
  }

  /// Cleanup khi không còn sử dụng
  void dispose() {
    _minimizedStateController.close();
  }

  // ignore: use_setters_to_change_properties
  void updateContent(String? content) {
    _content = content;
  }
}
