// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';

import '../../domain/entities/record_data.dart';
import '../../domain/usecase/speech_to_text_usecase.dart';
import '../../presentation/record_modal/bloc/speech_text_bloc.dart';
import '../../presentation/record_modal/record_session_manager.dart';
import '../../presentation/shared/app_dialog.dart';
import '../utils/logs/debug_print/record_modal_service_log.dart';

class RecordModalService {
  RecordModalService._();

  static final RecordModalService instance = RecordModalService._();

  BuildContext get context => _navigatorKey!.currentContext!;

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _hasOpenModal = false;

  /// Current user ID for pending recording persistence.
  /// Set this before opening the modal to enable crash recovery.
  String? currentUserId;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    debugPrintInitialized();
  }

  /// Set the current user ID for pending recording persistence.
  /// Call this when user logs in.
  void setCurrentUserId(String? userId) {
    currentUserId = userId;
    debugPrintSetCurrentUserId(userId);
  }

  bool get hasOpenModal => _hasOpenModal;

  Future<RecordData?> openModal<T>({
    required String locale,
    required T data,
    String? transcript,
    Future<bool?> Function(BuildContext)? onExit,
    bool restoreFromSession = false,
    required bool Function(T dataCurrent, T data) isSameData,
    required bool Function(T data) validData,
    String? customData,
  }) async {
    // Assertion check cho navigator key initialization
    assert(
      _navigatorKey != null,
      'RecordModalService must be initialized with navigator key first. '
      'Call RecordModalService.instance.initialize(navigatorKey) in '
      'Application.initState()',
    );

    if (_navigatorKey == null) {
      debugPrintNavigatorKeyNotInitialized();
      return null;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null || !context.mounted) {
      debugPrintContextNotAvailable();
      return null;
    }

    final sessionManager = RecordSessionManager.instance;

    // Kiểm tra xem có session đang active không
    if (sessionManager.hasActiveSession && !restoreFromSession) {
      final sessionData = sessionManager.data;

      if (sessionData is T) {
        final dataCurrent = data;

        // Nếu appointmentIdEmr giống nhau, restore modal hiện tại
        if (dataCurrent != null || isSameData(sessionData, dataCurrent)) {
          debugPrintRestoringExistingSession();

          // Restore modal với session hiện tại
          return openModal<T>(
            locale: sessionManager.locale ?? locale,
            data: dataCurrent,
            transcript: transcript,
            onExit: onExit,
            restoreFromSession: true,
            isSameData: isSameData,
            validData: validData,
          );
        }

        final validdataCurrent = validData(dataCurrent);
        // Nếu appointmentIdEmr khác nhau, hiện dialog cảnh báo
        if (validdataCurrent) {
          debugPrintDifferentAppointmentDetected();

          // Hiện dialog thông báo
          final shouldRestore = await context.showRecordingInProgressDialog();

          // Nếu user chọn mở lại, restore session hiện tại
          if (shouldRestore == true) {
            debugPrintUserChoseToRestore();

            return openModal(
              locale: sessionManager.locale ?? locale,
              data: sessionData,
              transcript: sessionManager.title,
              onExit: sessionManager.onExit,
              restoreFromSession: true,
              isSameData: isSameData,
              validData: validData,
            );
          }

          // User chọn hủy
          debugPrintUserCancelledOpening();
          return null;
        }
      }
    }

    debugPrintOpeningModal(restoreFromSession);

    // Nếu restore from session, sử dụng bloc hiện có
    final SpeechTextBloc bloc;

    // Error handling cho trường hợp restore session không tồn tại
    if (restoreFromSession && !sessionManager.hasActiveSession) {
      debugPrintWarningRestoreNoActiveSession();
    }

    if (restoreFromSession && sessionManager.hasActiveSession) {
      // Restore từ session đã có
      final existingBloc = sessionManager.bloc;
      if (existingBloc == null) {
        debugPrintSessionExistsButBlocNull();
        bloc = SpeechTextBloc(_createSpeechToTextUsecase(
          locale: locale,
          title: transcript,
          customData: customData,
        ));
        sessionManager
          ..updateData(data)
          ..startSession(
            bloc: bloc,
            locale: locale,
            title: transcript,
            onExit: onExit,
          );
      } else {
        bloc = existingBloc;
        debugPrintRestoringFromExistingSession(
          bloc.state.runtimeType,
          sessionManager.isPipelineActive,
        );
      }
    } else {
      // Tạo bloc mới và start session
      bloc = SpeechTextBloc(_createSpeechToTextUsecase(
        locale: locale,
        title: transcript,
        customData: customData,
      ));
      sessionManager
        ..updateData(data)
        ..startSession(
          bloc: bloc,
          locale: locale,
          title: transcript,
          onExit: onExit,
        );
      debugPrintCreatedNewSession(bloc.state.runtimeType);
    }

    final height = MediaQuery.of(context).size.height;

    // Track nếu user explicitly close (không phải minimize)
    bool userExplicitlyClosed = false;

    _hasOpenModal = true;

    RecordData? result;
    try {
      debugPrintShowingModalBottomSheet();
      result = await context.showRecordModal(
        bloc: bloc,
        maxHeight: height,
        onExit: onExit,
        transcript: transcript,
        locale: locale,
        restoreFromSession: restoreFromSession,
        sessionManager: sessionManager,
        onUpdateUserExplicitlyClosed: (shouldClose) {
          userExplicitlyClosed = shouldClose;
        },
      );

      debugPrintModalBottomSheetCompleted();
    } catch (e, stackTrace) {
      debugPrintFailedToShowModal(e, stackTrace);
      _hasOpenModal = false;

      // End session on error to cleanup resources
      sessionManager.endSession(disposeResources: true);

      rethrow;
    }

    _hasOpenModal = false;

    debugPrintModalClosed(
      result,
      userExplicitlyClosed,
      sessionManager.isMinimized,
      sessionManager.hasActiveSession,
    );

    // Xử lý kết quả modal
    if (result != null) {
      // User đã save - caller sẽ xử lý upload
      debugPrintUserSavedRecording(
        result.totalTime,
        result.content?.length ?? 0,
      );
    } else if (userExplicitlyClosed) {
      // User nhấn close button (cancel) - dispose resources
      debugPrintUserCancelledEndingSession();
      sessionManager.endSession(disposeResources: true);
    } else if (sessionManager.isMinimized) {
      // User minimize - giữ session
      debugPrintUserMinimizedKeepingSession(sessionManager.isPipelineActive);
      // Không làm gì, session vẫn active
    } else {
      // User dismiss modal bằng swipe down hoặc tap outside - Minimize!
      debugPrintUserDismissedModalMinimizing();
      sessionManager.minimizeSession();
    }

    return result;
  }

  void closeModal() {
    debugPrintCloseModalCalled(_hasOpenModal);

    if (!_hasOpenModal) {
      debugPrintWarningCloseModalNoModal();
      return;
    }

    if (_navigatorKey == null) {
      debugPrintCannotCloseModalNavigatorKeyNull();
      return;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null) {
      debugPrintCannotCloseModalContextNull();
      return;
    }

    if (!context.mounted) {
      debugPrintCannotCloseModalContextNotMounted();
      return;
    }

    try {
      Navigator.of(context).pop();
      debugPrintModalClosedProgrammatically();
    } catch (e, stackTrace) {
      debugPrintFailedToCloseModal(e, stackTrace);
    }
  }

  /// Create a SpeechToTextUsecase with pending recording config if user is set
  SpeechToTextUsecase _createSpeechToTextUsecase({
    required String locale,
    String? title,
    String? customData,
  }) {
    PendingRecordingConfig? pendingConfig;

    if (currentUserId != null && currentUserId!.isNotEmpty) {
      pendingConfig = PendingRecordingConfig(
        userId: currentUserId!,
        title: title,
        customData: customData,
        enablePersistence: true,
      );
    }

    return SpeechToTextUsecase(
      local: locale,
      pendingRecordingConfig: pendingConfig,
    );
  }
}
