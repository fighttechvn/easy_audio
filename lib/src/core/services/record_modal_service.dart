// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/record_data.dart';
import '../../domain/usecase/speech_to_text_usecase.dart';
import '../../presentation/record_modal/bloc/speech_text_bloc.dart';
import '../../presentation/record_modal/record_modal_widget.dart';
import '../../presentation/record_modal/record_session_manager.dart';

class RecordModalService {
  RecordModalService._();

  static final RecordModalService instance = RecordModalService._();

  BuildContext get context => _navigatorKey!.currentContext!;

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _hasOpenModal = false;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    debugPrint('[RecordModalService] Initialized with navigator key');
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
  }) async {
    // Assertion check cho navigator key initialization
    assert(
      _navigatorKey != null,
      'RecordModalService must be initialized with navigator key first. '
      'Call RecordModalService.instance.initialize(navigatorKey) in '
      'Application.initState()',
    );

    if (_navigatorKey == null) {
      debugPrint(
        '[RecordModalService] ERROR: Navigator key not initialized! '
        'Cannot open modal.',
      );
      return null;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null || !context.mounted) {
      debugPrint(
        '[RecordModalService] ERROR: Cannot open modal - '
        'context not available or not mounted',
      );
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
          debugPrint(
            '[RecordModalService] Same appointment detected, '
            'restoring existing session',
          );

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
          debugPrint('[RecordModalService] Different appointment detected');

          // Hiện dialog thông báo
          final shouldRestore = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Recording in Progress'),
              content: const Text(
                'There is currently an active recording session. '
                'You need to end the current recording session before starting a new one.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Reopen Recording Session'),
                ),
              ],
            ),
          );

          // Nếu user chọn mở lại, restore session hiện tại
          if (shouldRestore == true) {
            debugPrint(
              '[RecordModalService] User chose to restore existing session',
            );

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
          debugPrint('[RecordModalService] User cancelled opening new modal');
          return null;
        }
      }
    }

    debugPrint('[RecordModalService] Opening modal - '
        'restoreFromSession: $restoreFromSession, ');

    // Nếu restore from session, sử dụng bloc hiện có
    final SpeechTextBloc bloc;

    // Error handling cho trường hợp restore session không tồn tại
    if (restoreFromSession && !sessionManager.hasActiveSession) {
      debugPrint(
        '[RecordModalService] WARNING: Restore requested but no active '
        'session found. Creating new session instead.',
      );
    }

    if (restoreFromSession && sessionManager.hasActiveSession) {
      // Restore từ session đã có
      final existingBloc = sessionManager.bloc;
      if (existingBloc == null) {
        debugPrint(
          '[RecordModalService] ERROR: Session exists but bloc is null! '
          'Creating new session.',
        );
        bloc = SpeechTextBloc(SpeechToTextUsecase(local: locale));
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
        debugPrint(
          '[RecordModalService] Restoring from existing session - '
          'bloc state: ${bloc.state.runtimeType}, '
          'isPipelineActive: ${sessionManager.isPipelineActive}',
        );
      }
    } else {
      // Tạo bloc mới và start session
      bloc = SpeechTextBloc(SpeechToTextUsecase(local: locale));
      sessionManager
        ..updateData(data)
        ..startSession(
          bloc: bloc,
          locale: locale,
          title: transcript,
          onExit: onExit,
        );
      debugPrint(
        '[RecordModalService] Created new session - bloc state: ${bloc.state.runtimeType}',
      );
    }

    final height = MediaQuery.of(context).size.height;

    // Track nếu user explicitly close (không phải minimize)
    bool userExplicitlyClosed = false;

    _hasOpenModal = true;

    RecordData? result;
    try {
      debugPrint('[RecordModalService] Showing modal bottom sheet...');
      result = await showModalBottomSheet<RecordData?>(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        constraints: BoxConstraints(maxHeight: height),
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.25,
            maxChildSize: 0.7,
            snap: true,
            snapSizes: const [0.3, 0.5, 0.7],
            builder: (ct, controller) {
              return BlocProvider<SpeechTextBloc>.value(
                value: bloc,
                child: RecordModalWidget(
                  onExits: () async {
                    // User nhấn close button
                    debugPrint(
                      '[RecordModalService] User clicked close button',
                    );
                    if (context.mounted) {
                      final shouldClose =
                          await onExit?.call(context.mounted ? context : ct) ??
                              true;
                      if (shouldClose) {
                        userExplicitlyClosed = true;
                        debugPrint(
                          '[RecordModalService] User confirmed close',
                        );
                      } else {
                        debugPrint(
                          '[RecordModalService] User cancelled close',
                        );
                      }
                      return shouldClose;
                    }
                    return true;
                  },
                  title: transcript,
                  locale: locale,
                  restoreFromSession: restoreFromSession,
                  onShouldMinimize: () {
                    debugPrint(
                      '[RecordModalService] Minimize button clicked',
                    );
                    sessionManager.minimizeSession();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              );
            },
          );
        },
      );
      debugPrint('[RecordModalService] Modal bottom sheet completed');
    } catch (e, stackTrace) {
      debugPrint(
        '[RecordModalService] ERROR: Failed to show modal bottom sheet',
      );
      debugPrint('[RecordModalService] Error: $e');
      debugPrint('[RecordModalService] StackTrace: $stackTrace');
      _hasOpenModal = false;

      // End session on error to cleanup resources
      sessionManager.endSession(disposeResources: true);

      rethrow;
    }

    _hasOpenModal = false;

    debugPrint(
      '[RecordModalService] Modal closed - '
      'result: ${result != null ? "RecordData" : "null"}, '
      'userExplicitlyClosed: $userExplicitlyClosed, '
      'isMinimized: ${sessionManager.isMinimized}, '
      'hasActiveSession: ${sessionManager.hasActiveSession}',
    );

    // Xử lý kết quả modal
    if (result != null) {
      // User đã save - caller sẽ xử lý upload
      debugPrint(
        '[RecordModalService] User saved recording - '
        'duration: ${result.totalTime}, '
        'contentLength: ${result.content?.length ?? 0}',
      );
    } else if (userExplicitlyClosed) {
      // User nhấn close button (cancel) - dispose resources
      debugPrint(
        '[RecordModalService] User cancelled, ending session',
      );
      sessionManager.endSession(disposeResources: true);
    } else if (sessionManager.isMinimized) {
      // User minimize - giữ session
      debugPrint(
        '[RecordModalService] User minimized, keeping session alive - '
        'isPipelineActive: ${sessionManager.isPipelineActive}',
      );
      // Không làm gì, session vẫn active
    } else {
      // User dismiss modal bằng swipe down hoặc tap outside - Minimize!
      debugPrint(
        '[RecordModalService] User dismissed modal, minimizing',
      );
      sessionManager.minimizeSession();
    }

    return result;
  }

  void closeModal() {
    debugPrint(
      '[RecordModalService] closeModal called - '
      'hasOpenModal: $_hasOpenModal',
    );

    if (!_hasOpenModal) {
      debugPrint(
        '[RecordModalService] WARNING: closeModal called but '
        'no modal is open',
      );
      return;
    }

    if (_navigatorKey == null) {
      debugPrint(
        '[RecordModalService] ERROR: Cannot close modal - '
        'navigator key is null',
      );
      return;
    }

    final context = _navigatorKey!.currentContext;
    if (context == null) {
      debugPrint(
        '[RecordModalService] ERROR: Cannot close modal - '
        'context is null',
      );
      return;
    }

    if (!context.mounted) {
      debugPrint(
        '[RecordModalService] ERROR: Cannot close modal - '
        'context not mounted',
      );
      return;
    }

    try {
      Navigator.of(context).pop();
      debugPrint('[RecordModalService] Modal closed programmatically');
    } catch (e, stackTrace) {
      debugPrint(
        '[RecordModalService] ERROR: Failed to close modal',
      );
      debugPrint('[RecordModalService] Error: $e');
      debugPrint('[RecordModalService] StackTrace: $stackTrace');
    }
  }
}
