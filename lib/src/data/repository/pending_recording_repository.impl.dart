import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/pending_recording.dart';
import '../../domain/entities/record_session.dart';
import '../../domain/repository/pending_recording_repository.dart';
import '../datasources/pending_recording_local_datasource.dart';

@LazySingleton(as: PendingRecordingRepository)
class PendingRecordingRepositoryImpl implements PendingRecordingRepository {
  PendingRecordingRepositoryImpl({
    required PendingRecordingLocalDataSource local,
  }) : _local = local;

  final PendingRecordingLocalDataSource _local;

  bool _initialized = false;
  List<PendingRecording> _items = const <PendingRecording>[];

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await _local.init();

    final loaded = await _local.loadItems();
    _items = await _local.refreshFileSizesFor(loaded);
    await _local.persistItems(_items);

    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('PendingRecordingRepository not initialized');
    }
  }

  @override
  String get baseDirectoryPath {
    _ensureInitialized();
    return _local.baseDirectoryPath;
  }

  @override
  File fileFor(String fileName) {
    _ensureInitialized();
    return _local.fileFor(fileName);
  }

  @override
  List<PendingRecording> listForUser(int? userId) {
    _ensureInitialized();
    return _items
        .where((e) => userId == null || e.userId == null || e.userId == userId)
        .toList(growable: false);
  }

  @override
  List<PendingRecording> listForAppointment({
    required String appointmentIdEmr,
    required int? userId,
  }) {
    _ensureInitialized();

    final key = appointmentIdEmr.trim();
    return _items
        .where((e) => e.appointmentIdEmr.trim() == key)
        .where((e) => userId == null || e.userId == null || e.userId == userId)
        .toList(growable: false);
  }

  @override
  PendingRecording? getById(String id) {
    _ensureInitialized();

    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(PendingRecording recording) async {
    await init();

    final next = <PendingRecording>[];
    var replaced = false;

    for (final item in _items) {
      if (item.id == recording.id) {
        next.add(recording);
        replaced = true;
      } else {
        next.add(item);
      }
    }

    if (!replaced) {
      next.add(recording);
    }

    _items = next;
    await _local.persistItems(_items);
  }

  @override
  Future<void> deleteById(String id, {bool deleteFile = false}) async {
    await init();

    PendingRecording? removed;
    final next = <PendingRecording>[];

    for (final item in _items) {
      if (item.id == id) {
        removed = item;
      } else {
        next.add(item);
      }
    }

    _items = next;
    await _local.persistItems(_items);

    if (deleteFile && removed != null) {
      final f = File(removed.filePath);
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  @override
  Future<void> pruneMissingFiles() async {
    await init();

    final next = <PendingRecording>[];
    var changed = false;

    for (final item in _items) {
      final fileExists = await File(item.filePath).exists();
      if (fileExists) {
        next.add(item);
      } else {
        changed = true;
      }
    }

    if (!changed) {
      return;
    }

    _items = next;
    _items = await _local.refreshFileSizesFor(_items);
    await _local.persistItems(_items);
  }

  @override
  Future<void> refreshFileSizes() async {
    await init();

    final refreshed = await _local.refreshFileSizesFor(_items);
    if (!listEquals(refreshed, _items)) {
      _items = refreshed;
      await _local.persistItems(_items);
    }
  }

  @override
  Future<void> saveSessionToCache(RecordSession session) {
    return _local.saveSessionToCache(session);
  }

  @override
  Future<void> clearSessionCache() {
    return _local.clearSessionCache();
  }

  @override
  Future<RecordSession?> loadSessionFromCache() {
    return _local.loadSessionFromCache();
  }
}
