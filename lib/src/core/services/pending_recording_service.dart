import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a pending recording that was interrupted
/// (e.g., due to app crash, battery drain, or force close).
class PendingRecording {
  const PendingRecording({
    required this.id,
    required this.filePath,
    required this.userId,
    required this.locale,
    required this.startedAt,
    required this.duration,
    this.transcript,
    this.title,
    this.customData,
  });

  /// Unique identifier for this recording session
  final String id;

  /// Path to the audio file
  final String filePath;

  /// User identifier who created this recording
  final String userId;

  /// Locale used for speech-to-text
  final String locale;

  /// When the recording was started
  final DateTime startedAt;

  /// Estimated duration of the recording
  final Duration duration;

  /// Transcript content (if any was captured)
  final String? transcript;

  /// Title/label for the recording
  final String? title;

  /// Custom data from the app (serialized as JSON string)
  /// This can contain appointment ID, patient info, etc.
  final String? customData;

  /// Check if the audio file still exists
  Future<bool> get fileExists async {
    try {
      return await File(filePath).exists();
    } catch (_) {
      return false;
    }
  }

  /// Get the file size in bytes
  Future<int> get fileSize async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'userId': userId,
        'locale': locale,
        'startedAt': startedAt.toIso8601String(),
        'duration': duration.inMilliseconds,
        'transcript': transcript,
        'title': title,
        'customData': customData,
      };

  factory PendingRecording.fromJson(Map<String, dynamic> json) {
    return PendingRecording(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      userId: json['userId'] as String,
      locale: json['locale'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: Duration(milliseconds: json['duration'] as int),
      transcript: json['transcript'] as String?,
      title: json['title'] as String?,
      customData: json['customData'] as String?,
    );
  }

  PendingRecording copyWith({
    String? id,
    String? filePath,
    String? userId,
    String? locale,
    DateTime? startedAt,
    Duration? duration,
    String? transcript,
    String? title,
    String? customData,
  }) {
    return PendingRecording(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      userId: userId ?? this.userId,
      locale: locale ?? this.locale,
      startedAt: startedAt ?? this.startedAt,
      duration: duration ?? this.duration,
      transcript: transcript ?? this.transcript,
      title: title ?? this.title,
      customData: customData ?? this.customData,
    );
  }
}

/// Service to manage pending recordings that may have been interrupted.
///
/// This service persists recording session metadata to SharedPreferences,
/// allowing recovery of recordings when the app is reopened after an
/// unexpected termination.
///
/// Usage:
/// ```dart
/// // Start tracking a recording session
/// await PendingRecordingService.instance.startSession(
///   filePath: '/path/to/recording.wav',
///   userId: 'user123',
///   locale: 'en-US',
///   title: 'Consultation Note',
///   customData: jsonEncode({'appointmentId': 'apt123'}),
/// );
///
/// // Update session periodically (e.g., transcript updates)
/// await PendingRecordingService.instance.updateSession(
///   transcript: 'Updated transcript...',
///   duration: Duration(seconds: 30),
/// );
///
/// // End session normally (removes from pending)
/// await PendingRecordingService.instance.endSession();
///
/// // On app restart, check for pending recordings
/// final pending = await PendingRecordingService.instance
///     .getPendingRecordingsForUser('user123');
/// ```
class PendingRecordingService {
  PendingRecordingService._();

  static final PendingRecordingService instance = PendingRecordingService._();

  static const String _keyPendingRecordings = 'easy_audio_pending_recordings';
  static const String _keyActiveSession = 'easy_audio_active_session';

  /// How often to auto-save session updates (default: 3 seconds)
  static const Duration autoSaveInterval = Duration(seconds: 3);

  String? _activeSessionId;
  PendingRecording? _activeSession;

  /// Get the currently active session (if any)
  PendingRecording? get activeSession => _activeSession;

  /// Check if there's an active recording session
  bool get hasActiveSession => _activeSessionId != null;

  /// Start a new recording session and persist it immediately.
  ///
  /// [filePath] - Path to the audio file being recorded
  /// [userId] - User identifier (for multi-user support)
  /// [locale] - Language/locale for speech-to-text
  /// [title] - Optional title for the recording
  /// [customData] - Optional JSON-encoded custom data from the app
  Future<PendingRecording> startSession({
    required String filePath,
    required String userId,
    required String locale,
    String? title,
    String? customData,
  }) async {
    // Generate unique session ID
    final sessionId = _generateSessionId();

    final recording = PendingRecording(
      id: sessionId,
      filePath: filePath,
      userId: userId,
      locale: locale,
      startedAt: DateTime.now(),
      duration: Duration.zero,
      title: title,
      customData: customData,
    );

    _activeSessionId = sessionId;
    _activeSession = recording;

    // Persist immediately
    await _saveActiveSession();
    await _addToPendingList(recording);

    debugPrint(
      '[PendingRecordingService] Started session: $sessionId '
      'for user: $userId',
    );

    return recording;
  }

  /// Update the current active session with new data.
  ///
  /// Call this periodically to update transcript and duration.
  Future<void> updateSession({
    String? transcript,
    Duration? duration,
    String? customData,
  }) async {
    if (_activeSession == null) {
      debugPrint(
        '[PendingRecordingService] WARNING: updateSession called '
        'but no active session',
      );
      return;
    }

    _activeSession = _activeSession!.copyWith(
      transcript: transcript ?? _activeSession!.transcript,
      duration: duration ?? _activeSession!.duration,
      customData: customData ?? _activeSession!.customData,
    );

    await _saveActiveSession();
    await _updateInPendingList(_activeSession!);
  }

  /// End the current session normally.
  ///
  /// This removes the session from the pending list since it was
  /// completed successfully.
  Future<void> endSession() async {
    if (_activeSessionId == null) {
      debugPrint(
        '[PendingRecordingService] WARNING: endSession called '
        'but no active session',
      );
      return;
    }

    debugPrint(
      '[PendingRecordingService] Ending session: $_activeSessionId',
    );

    // Remove from pending list
    await _removeFromPendingList(_activeSessionId!);
    await _clearActiveSession();

    _activeSessionId = null;
    _activeSession = null;
  }

  /// Cancel and discard the current session.
  ///
  /// This removes the session from pending list and optionally
  /// deletes the audio file.
  Future<void> cancelSession({bool deleteFile = true}) async {
    if (_activeSession == null) {
      return;
    }

    final filePath = _activeSession!.filePath;

    await _removeFromPendingList(_activeSessionId!);
    await _clearActiveSession();

    if (deleteFile) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint(
            '[PendingRecordingService] Deleted cancelled recording: $filePath',
          );
        }
      } catch (e) {
        debugPrint(
          '[PendingRecordingService] Failed to delete file: $e',
        );
      }
    }

    _activeSessionId = null;
    _activeSession = null;
  }

  /// Get all pending recordings for a specific user.
  ///
  /// Call this on app startup to check for interrupted recordings.
  Future<List<PendingRecording>> getPendingRecordingsForUser(
    String userId,
  ) async {
    final allPending = await _getAllPendingRecordings();

    // Filter by user and verify files exist
    final userPending = <PendingRecording>[];
    for (final recording in allPending) {
      if (recording.userId == userId && await recording.fileExists) {
        userPending.add(recording);
      }
    }

    debugPrint(
      '[PendingRecordingService] Found ${userPending.length} pending '
      'recordings for user: $userId',
    );

    return userPending;
  }

  /// Get all pending recordings regardless of user.
  Future<List<PendingRecording>> getAllPendingRecordings() async {
    final allPending = await _getAllPendingRecordings();

    // Verify files exist
    final validPending = <PendingRecording>[];
    for (final recording in allPending) {
      if (await recording.fileExists) {
        validPending.add(recording);
      }
    }

    return validPending;
  }

  /// Mark a pending recording as handled (uploaded or discarded).
  ///
  /// Call this after the user decides what to do with the pending recording.
  Future<void> markAsHandled(
    String recordingId, {
    bool deleteFile = false,
  }) async {
    final recording = await _getPendingRecording(recordingId);
    if (recording == null) {
      return;
    }

    await _removeFromPendingList(recordingId);

    if (deleteFile) {
      try {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best effort cleanup
      }
    }

    debugPrint(
      '[PendingRecordingService] Marked as handled: $recordingId '
      '(deleted: $deleteFile)',
    );
  }

  /// Clean up old pending recordings that are older than [maxAge].
  ///
  /// Call this periodically to prevent storage bloat.
  Future<int> cleanupOldRecordings({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final allPending = await _getAllPendingRecordings();
    final cutoff = DateTime.now().subtract(maxAge);
    var cleanedCount = 0;

    for (final recording in allPending) {
      if (recording.startedAt.isBefore(cutoff)) {
        await markAsHandled(recording.id, deleteFile: true);
        cleanedCount++;
      }
    }

    if (cleanedCount > 0) {
      debugPrint(
        '[PendingRecordingService] Cleaned up $cleanedCount old recordings',
      );
    }

    return cleanedCount;
  }

  /// Restore active session on app restart.
  ///
  /// Call this early in app initialization to restore any interrupted session.
  Future<PendingRecording?> restoreActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyActiveSession);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final recording = PendingRecording.fromJson(json);

      // Verify file still exists
      if (!await recording.fileExists) {
        await _clearActiveSession();
        return null;
      }

      _activeSessionId = recording.id;
      _activeSession = recording;

      debugPrint(
        '[PendingRecordingService] Restored active session: ${recording.id}',
      );

      return recording;
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to restore active session: $e',
      );
      return null;
    }
  }

  // ==================== Private Methods ====================

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'rec_${timestamp}_$random';
  }

  Future<void> _saveActiveSession() async {
    if (_activeSession == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_activeSession!.toJson());
      await prefs.setString(_keyActiveSession, jsonString);
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to save active session: $e',
      );
    }
  }

  Future<void> _clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveSession);
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to clear active session: $e',
      );
    }
  }

  Future<List<PendingRecording>> _getAllPendingRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPendingRecordings);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map(
              (item) => PendingRecording.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to get pending recordings: $e',
      );
      return [];
    }
  }

  Future<PendingRecording?> _getPendingRecording(String id) async {
    final allPending = await _getAllPendingRecordings();
    try {
      return allPending.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addToPendingList(PendingRecording recording) async {
    try {
      final allPending = await _getAllPendingRecordings();
      allPending.add(recording);
      await _savePendingList(allPending);
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to add to pending list: $e',
      );
    }
  }

  Future<void> _updateInPendingList(PendingRecording recording) async {
    try {
      final allPending = await _getAllPendingRecordings();
      final index = allPending.indexWhere((r) => r.id == recording.id);
      if (index >= 0) {
        allPending[index] = recording;
        await _savePendingList(allPending);
      }
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to update pending list: $e',
      );
    }
  }

  Future<void> _removeFromPendingList(String id) async {
    try {
      final allPending = await _getAllPendingRecordings();
      allPending.removeWhere((r) => r.id == id);
      await _savePendingList(allPending);
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to remove from pending list: $e',
      );
    }
  }

  Future<void> _savePendingList(List<PendingRecording> recordings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recordings.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_keyPendingRecordings, jsonString);
    } catch (e) {
      debugPrint(
        '[PendingRecordingService] Failed to save pending list: $e',
      );
    }
  }
}

/// Extension to get default pending recordings directory
extension PendingRecordingDirectory on PendingRecordingService {
  /// Get the directory for storing pending recordings
  Future<Directory> getPendingRecordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pendingDir = Directory('${appDir.path}/pending_recordings');
    if (!await pendingDir.exists()) {
      await pendingDir.create(recursive: true);
    }
    return pendingDir;
  }

  /// Generate a file path for a new pending recording
  Future<String> generatePendingRecordingPath() async {
    final dir = await getPendingRecordingsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${dir.path}/recording_$timestamp.wav';
  }
}
