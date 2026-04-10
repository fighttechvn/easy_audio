import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/data_record.dart';
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
      final sessionData = session.data;
      final data = <String, dynamic>{
        'dataRecord': <String, dynamic>{
          'id': sessionData.id,
          'data': sessionData.data,
        },
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

      final rawData = jsonDecode(json) as Map<String, dynamic>;

      final data = _parseDataFromSessionCache(rawData);

      return RecordSession(
        data: data,
        clinicName: rawData['clinicName'] as String?,
        patientName: rawData['patientName'] as String?,
        bookingDate: rawData['bookingDate'] as String?,
        bookingTime: rawData['bookingTime'] as String?,
        localeId: rawData['localeId'] as String?,
        startedAt:
            DateTime.tryParse(rawData['startedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

DataRecord<Map<String, dynamic>> _parseDataFromSessionCache(
  Map<String, dynamic> data,
) {
  final raw = data['dataRecord'];
  if (raw is Map) {
    final map = raw.cast<String, dynamic>();
    final id = (map['id'] ?? '').toString();
    final rawData = map['data'];
    final jsonMap = rawData is Map
        ? rawData.cast<String, dynamic>()
        : const <String, dynamic>{};

    return DataRecord<Map<String, dynamic>>(
      id: id,
      data: Map<String, dynamic>.from(jsonMap),
    );
  }

  return const DataRecord<Map<String, dynamic>>(
    id: '',
    data: <String, dynamic>{},
  );
}
