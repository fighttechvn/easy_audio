import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/pending_recording.dart';
import '../../domain/entities/record_session.dart';

@lazySingleton
class PendingRecordingLocalDataSource {
  PendingRecordingLocalDataSource();

  static const String _folderName = 'pending_recordings';
  static const String _prefsKey = 'pending_recordings.items.v1';
  static const String _kSessionCacheKey = 'record_session_cache';

  late final SharedPreferences _prefs;

  bool _initialized = false;
  Future<void>? _initInFlight;
  late final Directory _baseDir;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    final inflight = _initInFlight;
    if (inflight != null) {
      await inflight;
      return;
    }

    final future = _doInit();
    _initInFlight = future;
    try {
      await future;
    } finally {
      // Ensure we don't hold onto the future forever (also clears on error).
      _initInFlight = null;
    }
  }

  Future<void> _doInit() async {
    if (_initialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();

    final supportDir = await getApplicationSupportDirectory();
    _baseDir = Directory(p.join(supportDir.path, _folderName));
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }

    _initialized = true;
  }

  String get baseDirectoryPath {
    _ensureInitialized();
    return _baseDir.path;
  }

  File fileFor(String fileName) {
    _ensureInitialized();
    return File(p.join(_baseDir.path, fileName));
  }

  Future<List<PendingRecording>> loadItems() async {
    _ensureInitialized();

    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingRecording>[];
    }

    final decoded = jsonDecode(raw);

    final list = switch (decoded) {
      {'items': final List items} => items,
      final List items => items,
      _ => const [],
    };

    return list
        .whereType<Map>()
        .map((e) => PendingRecording.fromJson(e.cast<String, dynamic>()))
        .where((e) => e.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> persistItems(List<PendingRecording> items) async {
    _ensureInitialized();

    final payload = <String, dynamic>{
      'items': items.map((e) => e.toJson()).toList(growable: false),
    };

    await _prefs.setString(_prefsKey, jsonEncode(payload));
  }

  Future<List<PendingRecording>> refreshFileSizesFor(
    List<PendingRecording> items,
  ) async {
    if (items.isEmpty) {
      return items;
    }

    final next = <PendingRecording>[];

    for (final item in items) {
      final f = File(item.filePath);
      if (!await f.exists()) {
        next.add(item);
        continue;
      }

      final len = await f.length();
      if (len != item.fileSizeBytes) {
        next.add(item.copyWith(fileSizeBytes: len));
      } else {
        next.add(item);
      }
    }

    return next;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('PendingRecordingLocalDataSource not initialized');
    }
  }

  Future<void> saveSessionToCache(RecordSession session) async {
    try {
      await init();
      final data = <String, dynamic>{
        'appointmentIdEmr': session.appointmentIdEmr,
        'appointmentId': session.appointmentId,
        'clinicName': session.clinicName,
        'patientName': session.patientName,
        'bookingDate': session.bookingDate,
        'bookingTime': session.bookingTime,
        'localeId': session.localeId,
        'startedAt': session.startedAt.toIso8601String(),
      };
      await _prefs.setString(_kSessionCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> clearSessionCache() async {
    try {
      await init();
      await _prefs.remove(_kSessionCacheKey);
    } catch (_) {}
  }

  Future<RecordSession?> loadSessionFromCache() async {
    try {
      await init();
      final json = _prefs.getString(_kSessionCacheKey);
      if (json == null || json.isEmpty) {
        return null;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      return RecordSession(
        appointmentIdEmr: data['appointmentIdEmr'] as String? ?? '',
        appointmentId: data['appointmentId'] as int? ?? 0,
        clinicName: data['clinicName'] as String?,
        patientName: data['patientName'] as String?,
        bookingDate: data['bookingDate'] as String?,
        bookingTime: data['bookingTime'] as String?,
        localeId: data['localeId'] as String?,
        startedAt: DateTime.tryParse(data['startedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
