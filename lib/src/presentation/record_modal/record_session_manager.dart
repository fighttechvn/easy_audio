import 'dart:async';

import 'package:flutter/material.dart';

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
    debugPrint(
      '🎙️ [SessionManager] Starting new session - '
      'locale: $locale, '
      'hasTitle: ${title != null}',
    );
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
    debugPrint('🎙️ [SessionManager] Session started successfully');
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
      debugPrint(
        '🎙️ [SessionManager] WARNING: minimizeSession called but '
        'no active session!',
      );
      return;
    }
    debugPrint(
      '🎙️ [SessionManager] Minimizing session - '
      'isPipelineActive: $_isPipelineActive, '
      'hasCallback: ${_updateContentCallback != null}, '
      'contentLength: ${_content?.length ?? 0}',
    );
    _isMinimized = true;
    _minimizedStateController.add(true);
    debugPrint('🎙️ [SessionManager] Session minimized, emitted to stream');
  }

  /// Restore lại modal từ floating
  void restoreSession() {
    if (!hasActiveSession) {
      debugPrint(
        '🎙️ [SessionManager] WARNING: restoreSession called but '
        'no active session!',
      );
      return;
    }
    debugPrint(
      '🎙️ [SessionManager] Restoring session - '
      'isPipelineActive: $_isPipelineActive, '
      'hasCallback: ${_updateContentCallback != null}, '
      'contentLength: ${_content?.length ?? 0}, '
      'blocState: ${_bloc?.state.runtimeType}',
    );
    _isMinimized = false;
    _minimizedStateController.add(false);
    debugPrint('🎙️ [SessionManager] Session restored, emitted to stream');
  }

  /// Set callback để update content từ speech-to-text
  void setUpdateContentCallback(void Function(String)? callback) {
    final wasSet = _updateContentCallback != null;
    _updateContentCallback = callback;
    final isSet = callback != null;
    debugPrint(
      '🎙️ [SessionManager] Update content callback changed - '
      'from: ${wasSet ? "set" : "null"}, '
      'to: ${isSet ? "set" : "null"}',
    );
  }

  /// Set trạng thái pipeline active/inactive
  void setPipelineActive(bool active) {
    final wasActive = _isPipelineActive;
    _isPipelineActive = active;
    debugPrint(
      '🎙️ [SessionManager] Pipeline state changed - '
      'from: $wasActive, '
      'to: $active, '
      'hasCallback: ${_updateContentCallback != null}',
    );
  }

  /// Restart pipeline nếu cần khi restore session
  void restartPipelineIfNeeded(SpeechTextBloc bloc) {
    debugPrint(
      '🎙️ [SessionManager] Checking if pipeline restart needed - '
      'isPipelineActive: $_isPipelineActive, '
      'hasCallback: ${_updateContentCallback != null}, '
      'blocClosed: ${bloc.isClosed}',
    );

    if (!_isPipelineActive && _updateContentCallback != null) {
      if (!bloc.isClosed) {
        debugPrint(
          '🎙️ [SessionManager] Restarting pipeline with saved callback',
        );
        bloc.add(StartRecordEvent(callbackToText: _updateContentCallback!));
        _isPipelineActive = true;
        debugPrint('🎙️ [SessionManager] Pipeline restarted successfully');
      } else {
        debugPrint(
          '🎙️ [SessionManager] ERROR: Cannot restart pipeline - '
          'bloc is closed',
        );
      }
    } else {
      debugPrint('🎙️ [SessionManager] Pipeline restart not needed');
    }
  }

  /// Kết thúc session và cleanup
  void endSession({bool disposeResources = true}) {
    debugPrint(
      '🎙️ [SessionManager] Ending session - '
      'disposeResources: $disposeResources, '
      'hadActiveSession: $hasActiveSession, '
      'isPipelineActive: $_isPipelineActive',
    );

    // Dispose bloc và controller nếu cần
    if (disposeResources) {
      if (_bloc != null && !_bloc!.isClosed) {
        debugPrint('🎙️ [SessionManager] Closing bloc');
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

    debugPrint('🎙️ [SessionManager] Session ended and cleaned up');
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
