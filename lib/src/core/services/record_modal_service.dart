// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/easy_record_configuration.dart';
import '../../domain/entities/record_data.dart';
import '../../domain/entities/record_session_data.dart';
import '../../domain/usecase/speech_to_text_usecase.dart';
import '../../presentation/record_modal/bloc/speech_text_bloc.dart';
import '../../presentation/record_modal/record_modal_widget.dart';
import '../../presentation/record_modal/record_session_manager.dart';

class EasyRecordModalService {
  EasyRecordModalService._();

  static final EasyRecordModalService instance = EasyRecordModalService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _hasOpenModal = false;
  EasyRecordConfiguration? _currentConfig;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    debugPrint('[EasyRecordModalService] Initialized with navigator key');
  }

  /// Whether a modal is currently open.
  bool get hasOpenModal => _hasOpenModal;

  /// The current configuration, if any.
  EasyRecordConfiguration? get currentConfig => _currentConfig;

  Future<RecordData?> openModal({
    required BuildContext context,
    required EasyRecordConfiguration config,
    bool restoreFromSession = false,
  }) async {
    // Use provided context or fall back to navigator key
    final effectiveContext =
        context.mounted ? context : _navigatorKey?.currentContext;

    if (effectiveContext == null || !effectiveContext.mounted) {
      debugPrint(
        '[EasyRecordModalService] ERROR: Cannot open modal - '
        'context not available or not mounted',
      );
      return null;
    }

    final sessionManager = RecordSessionManager.instance;
    final locale = config.defaultLocale;

    // Handle existing session
    if (sessionManager.hasActiveSession && !restoreFromSession) {
      final existingSessionData = sessionManager.data;

      if (existingSessionData is RecordSessionData) {
        final existingSessionId = existingSessionData.sessionId;
        final newSessionId = config.sessionData?.sessionId ?? '';

        // Same session, restore
        if (existingSessionId == newSessionId) {
          debugPrint(
            '[EasyRecordModalService] Same session detected, restoring',
          );
          return openModal(
            context: effectiveContext,
            config: config.copyWith(
              defaultLocale: sessionManager.locale ?? locale,
              title: sessionManager.title ?? config.title,
            ),
            restoreFromSession: true,
          );
        }

        // Different session - show warning
        if (existingSessionId.isNotEmpty && newSessionId.isNotEmpty) {
          debugPrint(
            '[EasyRecordModalService] Different session detected - '
            'existing: $existingSessionId, new: $newSessionId',
          );

          final shouldRestore =
              await _showSessionConflictDialog(effectiveContext);

          if (shouldRestore == true) {
            return openModal(
              context: effectiveContext,
              config: EasyRecordConfiguration(
                sessionData: existingSessionData,
                defaultLocale: sessionManager.locale ?? locale,
                title: sessionManager.title,
                onExitConfirmation: sessionManager.onExit,
                onRecordComplete: config.onRecordComplete,
              ),
              restoreFromSession: true,
            );
          }

          return null;
        }
      }
    }

    debugPrint(
      '[EasyRecordModalService] Opening modal - '
      'restoreFromSession: $restoreFromSession, '
      'sessionId: ${config.sessionData?.sessionId}',
    );

    // Create or restore bloc
    final SpeechTextBloc bloc;

    if (restoreFromSession && sessionManager.hasActiveSession) {
      final existingBloc = sessionManager.bloc;
      if (existingBloc == null) {
        debugPrint(
          '[EasyRecordModalService] WARNING: Session exists but bloc is null! '
          'Creating new session.',
        );
        bloc = SpeechTextBloc(SpeechToTextUsecase(local: locale));
        _startNewSession(sessionManager, bloc, config);
      } else {
        bloc = existingBloc;
        debugPrint(
          '[EasyRecordModalService] Restoring from existing session - '
          'bloc state: ${bloc.state.runtimeType}',
        );
      }
    } else {
      bloc = SpeechTextBloc(SpeechToTextUsecase(local: locale));
      _startNewSession(sessionManager, bloc, config);
    }

    _currentConfig = config;
    final height = MediaQuery.of(effectiveContext).size.height;

    bool userExplicitlyClosed = false;
    _hasOpenModal = true;

    RecordData? result;
    try {
      result = await showModalBottomSheet<RecordData?>(
        context: effectiveContext,
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
                    debugPrint(
                      '[EasyRecordModalService] User clicked close button',
                    );
                    if (effectiveContext.mounted) {
                      final shouldClose = await config.onExitConfirmation
                              ?.call(effectiveContext) ??
                          true;
                      if (shouldClose) {
                        userExplicitlyClosed = true;
                      }
                      return shouldClose;
                    }
                    return true;
                  },
                  title: config.title,
                  locale: locale,
                  restoreFromSession: restoreFromSession,
                  colorWaveformView: config.waveformColor,
                  onShouldMinimize: config.allowMinimize
                      ? () {
                          debugPrint(
                            '[EasyRecordModalService] Minimize button clicked',
                          );
                          sessionManager.minimizeSession();
                          config.onMinimize?.call();
                          Navigator.of(sheetContext).pop();
                        }
                      : null,
                ),
              );
            },
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[EasyRecordModalService] ERROR: Failed to show modal');
      debugPrint('[EasyRecordModalService] Error: $e');
      config.onError?.call(e, stackTrace);
      _hasOpenModal = false;
      sessionManager.endSession(disposeResources: true);
      rethrow;
    }

    _hasOpenModal = false;
    _currentConfig = null;

    debugPrint(
      '[EasyRecordModalService] Modal closed - '
      'result: ${result != null ? "RecordData" : "null"}, '
      'userExplicitlyClosed: $userExplicitlyClosed, '
      'isMinimized: ${sessionManager.isMinimized}',
    );

    // Handle result
    if (result != null) {
      // User saved - invoke callback
      debugPrint('[EasyRecordModalService] User saved recording');
      await config.onRecordComplete?.call(
        result,
        sessionManager.locale ?? locale,
        config.sessionData,
      );
      sessionManager.endSession(disposeResources: true);
    } else if (userExplicitlyClosed) {
      // User cancelled
      debugPrint('[EasyRecordModalService] User cancelled');
      sessionManager.endSession(disposeResources: true);
    } else if (sessionManager.isMinimized) {
      // User minimized
      debugPrint('[EasyRecordModalService] User minimized');
    } else {
      // User dismissed (swipe down)
      debugPrint('[EasyRecordModalService] User dismissed, minimizing');
      sessionManager.minimizeSession();
      config.onMinimize?.call();
    }

    return result;
  }

  void _startNewSession(
    RecordSessionManager sessionManager,
    SpeechTextBloc bloc,
    EasyRecordConfiguration config,
  ) {
    sessionManager
      ..updateData(config.sessionData)
      ..startSession(
        bloc: bloc,
        locale: config.defaultLocale,
        title: config.title,
        onExit: config.onExitConfirmation,
      );
    debugPrint(
      '[EasyRecordModalService] Created new session - '
      'sessionId: ${config.sessionData?.sessionId}',
    );
  }

  Future<bool?> _showSessionConflictDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recording in Progress'),
        content: const Text(
          'There is currently an active recording session. '
          'You need to end the current recording session before '
          'starting a new one.',
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
  }

  /// Closes the currently open modal programmatically.
  void closeModal() {
    if (!_hasOpenModal) {
      debugPrint('[EasyRecordModalService] WARNING: No modal is open');
      return;
    }

    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) {
      debugPrint('[EasyRecordModalService] ERROR: Cannot close - no context');
      return;
    }

    try {
      Navigator.of(context).pop();
      debugPrint('[EasyRecordModalService] Modal closed programmatically');
    } catch (e, stackTrace) {
      debugPrint('[EasyRecordModalService] ERROR: Failed to close: $e');
      debugPrint('$stackTrace');
    }
  }

  /// Gets the navigator key, if initialized.
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;
}
