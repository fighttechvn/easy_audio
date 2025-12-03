import 'package:flutter/material.dart';

import '../../core/services/record_modal_service.dart';
import '../../domain/entities/record_data.dart';
import '../record_modal/record_session_manager.dart';
import '../shared/record/bloc/record_bloc.dart';
import '../shared/record/entities/record_state_ui.dart';

/// Base mixin chứa các logic chung liên quan đến RecordSessionManager
/// và RecordBloc cho các screen có tính năng record audio.
///
/// Generic type [D] là kiểu dữ liệu của session data (ví dụ: RecordInfo)
///
/// Để sử dụng, extend mixin này và implement các abstract methods/getters.
mixin BaseRecordSessionMixin<T extends StatefulWidget, D> on State<T> {
  // ======== RecordSessionManager ========

  /// Truy cập RecordSessionManager singleton
  RecordSessionManager get recordSessionManager =>
      RecordSessionManager.instance;

  /// Kiểm tra xem có session đang active không
  bool get hasActiveRecordSession => recordSessionManager.hasActiveSession;

  /// Lấy data từ session hiện tại (cast về type D)
  D? get currentSessionData {
    final data = recordSessionManager.data;
    if (data is D) {
      return data;
    }
    return null;
  }

  /// Lấy identifier từ session hiện tại
  String? get currentSessionIdentifier {
    final data = currentSessionData;
    if (data != null) {
      return identifierFromData(data);
    }
    return null;
  }

  /// Kiểm tra xem session hiện tại có phải của identifier đang xem không
  bool isCurrentSessionFor(String? identifier) {
    return currentSessionIdentifier == identifier;
  }

  /// Kiểm tra xem có session khác đang active không
  bool hasOtherActiveSession(String? identifier) {
    if (!hasActiveRecordSession) {
      return false;
    }
    final existingIdentifier = currentSessionIdentifier;
    if (existingIdentifier == null || existingIdentifier.isEmpty) {
      return false;
    }
    return existingIdentifier != identifier;
  }

  /// Lấy locale từ session hoặc fallback
  String getSessionLocale(String? fallbackLocale) {
    return recordSessionManager.locale ?? fallbackLocale ?? 'en-US';
  }

  /// Lấy transcript/title từ session
  String? get sessionTranscript => recordSessionManager.title;

  /// Lấy onExit callback từ session
  Future<bool?> Function(BuildContext)? get sessionOnExitCallback =>
      recordSessionManager.onExit;

  /// Kết thúc session và cleanup
  void endRecordSession({bool disposeResources = true}) {
    recordSessionManager.endSession(disposeResources: disposeResources);
  }

  // ======== Abstract methods - Subclass PHẢI implement ========

  /// Lấy unique identifier từ session data
  String? identifierFromData(D data);

  /// Kiểm tra data có valid không
  bool validateData(D data);

  /// Tạo session data mới với các params cần thiết
  D createSessionData();

  /// Xử lý khi recording hoàn thành (upload, save, etc.)
  Future<void> onRecordComplete(RecordData result, D data);

  /// Lấy RecordBloc instance - subclass phải cung cấp
  RecordBloc get recordBloc;

  /// Request record permissions - subclass implement
  Future<bool> requestRecordPermissions();

  /// Lấy current app locale
  String getCurrentAppLocale();

  /// Tạo transcript label cho recording
  String createTranscriptLabel();

  /// Select language dialog - return locale string
  Future<String?> selectLanguage();

  /// Show dialog when recording in progress
  Future<bool?> showRecordingInProgressDialog();

  /// Show permission denied error
  void showPermissionDeniedError();

  /// Show file not found error
  void showFileNotFoundError();

  /// Show recording error
  void showRecordingError(Object error);

  /// Show empty file path error
  void showEmptyFilePathError();

  // ======== RecordBloc helpers ========

  /// Convenience getter cho stateUI
  RecordStateUI get recordStateUI => recordBloc.state.stateUI;

  /// Check if loading language model
  bool get isLoadingLanguageModel {
    final state = recordBloc.state;
    return state is PrepareLanguageModelLoading ||
        state is RecordLoadingLanguageModel;
  }

  /// Init audio player - call in initState
  void initAudioPlayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      recordBloc.add(InitAudioPlayerEvent());
    });
  }

  /// Dispose audio player - call in dispose
  void disposeAudioPlayer() {
    recordBloc.add(DisposeAudioPlayerEvent());
  }

  /// Play audio by url
  void playAudio(String url) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    recordBloc.add(PlayAudioEvent(url: url));
  }

  /// Stop current audio
  void stopAudio() {
    recordBloc.add(StopAudioEvent());
  }

  // ======== Dialog helpers ========

  /// Tạo onExit callback mặc định cho dialog xác nhận dừng recording
  Future<bool?> Function(BuildContext) createDefaultOnExitCallback() {
    return (ct) {
      if (!mounted && !ct.mounted) {
        return Future.value(false);
      }
      final ctDialog = mounted ? context : ct;
      return showStopRecordingConfirmDialog(ctDialog);
    };
  }

  /// Hiển thị dialog xác nhận dừng recording
  /// Subclass có thể override để customize dialog
  Future<bool?> showStopRecordingConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text(
          'Are you sure you want to stop the current recording session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  // ======== Recording flow ========

  /// Mở record modal và xử lý kết quả
  Future<RecordData?> openRecordModalWithSession({
    required String locale,
    D? data,
    String? transcript,
    Future<bool?> Function(BuildContext)? onExit,
    bool restoreFromSession = false,
  }) async {
    final sessionData = data ?? createSessionData();

    final result = await RecordModalService.instance.openModal<D>(
      locale: locale,
      data: sessionData,
      transcript: transcript,
      onExit: onExit,
      restoreFromSession: restoreFromSession,
      isSameData: (dataCurrent, dataNew) {
        final currentId = identifierFromData(dataCurrent);
        final dataId = identifierFromData(dataNew);
        return currentId == dataId;
      },
      validData: validateData,
    );

    if (result != null && RecordModalService.instance.context.mounted) {
      await onRecordComplete(result, sessionData);
      endRecordSession();
    }

    return result;
  }

  /// Start recording flow - main entry point
  Future<RecordData?> startRecordingFlow({
    bool restoreFromSession = false,
    bool useExistingSession = false,
  }) async {
    try {
      final granted = await requestRecordPermissions();
      if (!granted) {
        if (mounted) {
          showPermissionDeniedError();
        }
        return null;
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Stop current audio before recording
      playAudio('');

      // Prepare session data
      final D sessionData;
      final String locale;
      final String? transcript;
      final Future<bool?> Function(BuildContext)? onExitCallback;

      final existingSession = currentSessionData;
      if (useExistingSession &&
          hasActiveRecordSession &&
          existingSession != null) {
        sessionData = existingSession;
        locale = getSessionLocale(recordStateUI.currentLocale);
        transcript = sessionTranscript;
        onExitCallback = sessionOnExitCallback;
      } else {
        sessionData = createSessionData();
        locale = recordStateUI.currentLocale!;
        transcript = createTranscriptLabel();
        onExitCallback = createDefaultOnExitCallback();
      }

      final result = await openRecordModalWithSession(
        locale: locale,
        data: sessionData,
        transcript: transcript,
        onExit: onExitCallback,
        restoreFromSession: restoreFromSession,
      );

      if (!mounted || result == null) {
        return null;
      }

      if (result.url.isEmpty) {
        showEmptyFilePathError();
        return null;
      }

      return result;
    } catch (error, _) {
      if (mounted) {
        showRecordingError(error);
      }
      return null;
    } finally {
      recordBloc.add(RecordAudioDoneEvent());
    }
  }

  /// Handler cho tap record button - main flow
  Future<void> onTapRecordButton() async {
    if (isLoadingLanguageModel) {
      return;
    }

    // Check language loaded
    if (!recordStateUI.isLanguageLoaded) {
      recordBloc.add(
        RecordLoadSupportedLanguagesEvent(
          currentLocale: getCurrentAppLocale(),
          recordAfterLoaded: true,
        ),
      );
      return;
    }

    // Check existing session
    if (hasActiveRecordSession) {
      // Same session - restore
      if (isCurrentSessionFor(currentSessionIdentifier)) {
        await startRecordingFlow(restoreFromSession: true);
        return;
      }

      // Different session - show dialog
      if (hasOtherActiveSession(currentSessionIdentifier)) {
        final shouldRestore = await showRecordingInProgressDialog();
        if (shouldRestore == true) {
          await startRecordingFlow(
            restoreFromSession: true,
            useExistingSession: true,
          );
        }
        return;
      }
    }

    // Select language flow
    final selectedLocale = await selectLanguage();
    if (!mounted || selectedLocale == null || selectedLocale.isEmpty) {
      return;
    }

    if (selectedLocale != recordStateUI.currentLocale) {
      recordBloc.add(RecordPrepareLanguageModelEvent(locale: selectedLocale));
    } else {
      recordBloc.add(RecordingAudioEvent());
      await startRecordingFlow();
    }
  }

  /// Bloc listener handler - subclass có thể extend
  void onRecordBlocStateChanged(BuildContext context, RecordState state) {
    if (state is PrepareLanguageModelLoaded) {
      recordBloc.add(RecordingAudioEvent());
      startRecordingFlow();
    } else if (state is RecordLoaded && state.stateUI.recordAfterLoaded) {
      recordBloc.add(RecordResetStateEvent());
      onTapRecordButton();
    }
  }
}
