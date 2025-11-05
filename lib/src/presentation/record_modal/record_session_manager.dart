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
  Future<bool?> Function()? _onExit;

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
  Future<bool?> Function()? get onExit => _onExit;
  T? get data => _data;
  Stream<bool> get minimizedStateStream => _minimizedStateController.stream;

  /// Khởi tạo session mới
  void startSession({
    required SpeechTextBloc bloc,
    required String locale,
    String? title,
    Future<bool?> Function()? onExit,
  }) {
    _bloc = bloc;
    _recordStartedAt = DateTime.now();
    _pausedAccumulated = Duration.zero;
    _pausedAt = null;
    _isMinimized = false;
    _locale = locale;
    _title = title;
    _onExit = onExit;
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
          '🎙️ [SessionManager] minimizeSession called but no active session!');
      return;
    }
    debugPrint('🎙️ [SessionManager] Setting isMinimized = true');
    _isMinimized = true;
    _minimizedStateController.add(true);
    debugPrint('🎙️ [SessionManager] Emitted true to stream');
  }

  /// Restore lại modal từ floating
  void restoreSession() {
    if (!hasActiveSession) {
      return;
    }
    _isMinimized = false;
    _minimizedStateController.add(false);
  }

  /// Kết thúc session và cleanup
  void endSession({bool disposeResources = true}) {
    // Dispose bloc và controller nếu cần
    if (disposeResources) {
      _bloc?.close();
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
