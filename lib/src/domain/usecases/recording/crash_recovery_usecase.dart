import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../core/constants/easy_audio_locale_display.dart';
import '../../../core/utils/record_session_helper.dart';
import '../../../integration/audio/easy_audio/easy_audio_service.dart';
import '../../entities/data_record.dart';
import '../../entities/easy_audio_config.dart';
import '../../entities/pending_recording.dart';
import '../../entities/recording_result.dart';
import '../pending_recordings_usecase.dart';

class CrashRecoveryUnfinishedRecording {
  const CrashRecoveryUnfinishedRecording({
    required this.record,
    required this.languageDisplayName,
  });

  final PendingRecording record;
  final String languageDisplayName;
}

@injectable
class CrashRecoveryUsecase {
  const CrashRecoveryUsecase(this._pendingRecordingsUsecase);

  final PendingRecordingsUsecase _pendingRecordingsUsecase;

  Future<CrashRecoveryUnfinishedRecording?> runLoginCrashRecovery({
    required int userId,
    required String fallbackLocale,
  }) async {
    await _pendingRecordingsUsecase.init();
    await _pendingRecordingsUsecase.pruneMissingFiles();

    final easyAudio = EasyAudioService();
    if (!easyAudio.isInitialized) {
      await easyAudio.initialize(const EasyAudioConfig());
    }

    final recovered = await easyAudio.recoverLastRecording();
    if (recovered != null) {
      await _applyRecoveredRecording(
        userId: userId,
        fallbackLocale: fallbackLocale,
        recovered: recovered,
      );
    }

    final candidates = await _listCandidates(userId);
    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final record = candidates.first;

    final languageName = await _resolveLanguageDisplayName(
      easyAudio: easyAudio,
      localeId: record.locale,
    );

    return CrashRecoveryUnfinishedRecording(
      record: record,
      languageDisplayName: languageName,
    );
  }

  Future<List<PendingRecording>> _listCandidates(int userId) async {
    await _pendingRecordingsUsecase.init();

    final items = _pendingRecordingsUsecase.listForUser(userId);
    final candidates = <PendingRecording>[];

    for (final item in items) {
      if (item.status == PendingRecordingStatus.uploading) {
        continue;
      }

      if (await File(item.filePath).exists()) {
        candidates.add(item);
      }
    }

    return candidates;
  }

  Future<void> _applyRecoveredRecording({
    required int userId,
    required String fallbackLocale,
    required RecordingResult recovered,
  }) async {
    final filePath = (recovered.filePath ?? '').trim();
    if (filePath.isEmpty) {
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    PendingRecording? existing;
    final items = _pendingRecordingsUsecase.listForUser(userId);
    for (final item in items) {
      if ((item.userId == null || item.userId == userId) &&
          item.filePath.trim() == filePath) {
        existing = item;
        break;
      }
    }

    final parsed = RecordSessionHelper.parsePendingInfoFromRecordingFileName(
      filePath,
    );

    final cachedSession = await _pendingRecordingsUsecase
        .loadSessionFromCache();

    final locale = (recovered.localeId?.trim().isNotEmpty == true)
        ? recovered.localeId!.trim()
        : (existing?.locale.trim().isNotEmpty == true)
        ? existing!.locale.trim()
        : cachedSession?.localeId ?? fallbackLocale;

    final createdAt = recovered.startTime;
    final fileSize =
        recovered.fileSizeBytes ??
        (existing?.fileSizeBytes ?? await file.length());
    final durationMs = recovered.duration.inMilliseconds;
    final transcript = recovered.transcript?.trim() ?? '';

    if (existing == null) {
      final id = RecordSessionHelper.generatePendingRecordingId();

      final cachedContext = cachedSession?.data;
      final contextId = (cachedContext?.id.trim().isNotEmpty == true)
          ? cachedContext!.id
          : (parsed?.dataId ?? 'recovered');

      final legacyNumericId = parsed?.legacyNumericId;
      final contextData =
          cachedContext?.data ??
          <String, dynamic>{
            ...?legacyNumericId == null
                ? null
                : <String, dynamic>{'legacyNumericId': legacyNumericId},
          };

      final data = DataRecord<Map<String, dynamic>>(
        id: contextId,
        data: Map<String, dynamic>.from(contextData),
      );

      await _pendingRecordingsUsecase.upsert(
        PendingRecording(
          id: id,
          userId: userId,
          dataRecord: data,
          clinicName: cachedSession?.clinicName,
          patientName: cachedSession?.patientName,
          bookingDate: cachedSession?.bookingDate,
          bookingTime: cachedSession?.bookingTime,
          locale: locale,
          content: transcript,
          filePath: filePath,
          fileSizeBytes: fileSize,
          durationMs: durationMs,
          createdAt: createdAt,
          status: PendingRecordingStatus.pending,
          retryCount: 0,
          lastError: null,
        ),
      );

      await _pendingRecordingsUsecase.clearSessionCache();
      return;
    }

    final nextSize = recovered.fileSizeBytes ?? existing.fileSizeBytes;

    DataRecord<Map<String, dynamic>>? nextContext;
    if (cachedSession?.data.id.trim().isNotEmpty == true) {
      nextContext = cachedSession!.data;
    } else if (parsed != null) {
      final legacyNumericId = parsed.legacyNumericId;
      final data = <String, dynamic>{
        ...?legacyNumericId == null
            ? null
            : <String, dynamic>{'legacyNumericId': legacyNumericId},
      };
      nextContext = DataRecord<Map<String, dynamic>>(
        id: parsed.dataId,
        data: Map<String, dynamic>.from(data),
      );
    }

    final updated = existing.copyWith(
      userId: userId,
      fileSizeBytes: nextSize,
      dataRecord: nextContext,
      clinicName: cachedSession?.clinicName ?? existing.clinicName,
      patientName: cachedSession?.patientName ?? existing.patientName,
      bookingDate: cachedSession?.bookingDate ?? existing.bookingDate,
      bookingTime: cachedSession?.bookingTime ?? existing.bookingTime,
      locale: locale,
      content: transcript.isNotEmpty ? transcript : null,
      durationMs: durationMs > 0 ? durationMs : null,
      status: PendingRecordingStatus.pending,
      lastError: null,
    );

    await _pendingRecordingsUsecase.upsert(updated);
    await _pendingRecordingsUsecase.clearSessionCache();
  }

  Future<String> _resolveLanguageDisplayName({
    required EasyAudioService easyAudio,
    required String localeId,
  }) async {
    var languageName = EasyAudioLocaleDisplay.labelForLocaleId(
      localeId,
      fallback: 'Unknown',
    );

    try {
      final locales = await easyAudio.getSupportedLocales();
      final hit = locales.where((e) => e.localeId == localeId).toList();
      if (hit.isNotEmpty) {
        languageName = hit.first.name;
      }
    } catch (_) {
      // Best-effort.
    }

    return languageName;
  }
}
