import 'dart:async';
import 'dart:io';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/record_flow_constants.dart';
import '../../core/di/record_flow_injector.dart';
import '../../core/utils/formatters.dart';

class RecordFloatingOverlayHost extends StatefulWidget {
  const RecordFloatingOverlayHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<RecordFloatingOverlayHost> createState() =>
      _RecordFloatingOverlayHostState();
}

class _RecordFloatingOverlayHostState extends State<RecordFloatingOverlayHost> {
  bool _openingSheet = false;

  RecordSessionCubit get _recordSessionCubit =>
      injector.get<RecordSessionCubit>();
  PendingUploadBloc get _pendingUploadBloc => injector.get<PendingUploadBloc>();
  PendingRecordingsBloc get _pendingRecordingsBloc =>
      injector.get<PendingRecordingsBloc>();
  CrashRecoveryBloc get _crashRecoveryBloc => injector.get<CrashRecoveryBloc>();
  PendingUploadOrchestratorBloc get _pendingUploadOrchestrator =>
      injector.get<PendingUploadOrchestratorBloc>();

  NavigatorState? get _rootNavigator => widget.navigatorKey.currentState;

  Future<void> _openRecordingSheet() async {
    if (_openingSheet) {
      return;
    }

    final navigator = _rootNavigator;
    final session = _recordSessionCubit.state.session;
    if (navigator == null || session == null) {
      return;
    }

    _openingSheet = true;
    _recordSessionCubit.markSheetOpen();

    RecordingResult? result;
    try {
      result = await showModalBottomSheet<RecordingResult>(
        context: navigator.context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: true,
        builder: (context) {
          return RecordAudioBottomSheetWidget(
            easyAudio: _recordSessionCubit.easyAudio,
            localeId: session.localeId,
            enableAndroidBackgroundRecording: Platform.isAndroid,
            initialAmplitudeHistory:
                _recordSessionCubit.amplitudeHistorySnapshot,
            initialFinalTranscript: _recordSessionCubit.finalTranscriptSnapshot,
            initialLiveTranscript: _recordSessionCubit.liveTranscriptSnapshot,
            initialState: _recordSessionCubit.state.audioState,
            initialElapsed: _recordSessionCubit.state.elapsed,
            onMinimizeRequested: () async {
              await _recordSessionCubit.minimize();
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
            onCloseRequested: () async {
              await _recordSessionCubit.cancelAndDiscard();
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
          );
        },
      );
    } finally {
      _recordSessionCubit.markSheetClosed();
      _openingSheet = false;
    }

    if (!mounted) {
      return;
    }

    if (result == null) {
      unawaited(_recordSessionCubit.minimize());
      return;
    }

    await _recordSessionCubit.handleSheetResult(
      result: result,
      userId: recordFlowDemoUserId,
      fallbackLocale: Localizations.localeOf(context).toLanguageTag(),
    );
  }

  Future<void> _runCrashRecovery() async {
    final completer = Completer<void>();
    _crashRecoveryBloc.add(
      CrashRecoveryRunLoginRequested(
        userId: recordFlowDemoUserId,
        fallbackLocale: Localizations.localeOf(context).toLanguageTag(),
        completer: completer,
      ),
    );
    await completer.future;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runCrashRecovery());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _recordSessionCubit),
        BlocProvider.value(value: _crashRecoveryBloc),
        BlocProvider.value(value: _pendingUploadOrchestrator),
        BlocProvider.value(value: _pendingUploadBloc),
        BlocProvider.value(value: _pendingRecordingsBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<RecordSessionCubit, RecordSessionState>(
            listenWhen: (prev, next) =>
                prev.openSheetRequestId != next.openSheetRequestId,
            listener: (context, state) {
              unawaited(_openRecordingSheet());
            },
          ),
          BlocListener<RecordSessionCubit, RecordSessionState>(
            listenWhen: (prev, next) => prev.lastSavedAt != next.lastSavedAt,
            listener: (context, state) {
              _pendingRecordingsBloc.add(
                const PendingRecordingsRefreshRequested(),
              );
            },
          ),
          BlocListener<PendingUploadBloc, PendingUploadState>(
            listenWhen: (prev, next) => prev.lastResult != next.lastResult,
            listener: (context, state) {
              final result = state.lastResult;
              if (result == null) {
                return;
              }
              _recordSessionCubit.notifyUploadResult(
                appointmentIdEmr: result.appointmentIdEmr,
                success: result.success,
              );
              _pendingRecordingsBloc.add(
                const PendingRecordingsRefreshRequested(),
              );

              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? 'Uploaded recording successfully.'
                          : 'Upload failed.',
                    ),
                  ),
                );
              }
            },
          ),
          BlocListener<CrashRecoveryBloc, CrashRecoveryState>(
            listenWhen: (prev, next) =>
                prev.uiState.effectId != next.uiState.effectId &&
                next.uiState.effect != null,
            listener: (context, state) async {
              final effect = state.uiState.effect;
              if (effect == null || !mounted) {
                return;
              }

              if (effect.type == CrashRecoveryEffectType.showToast) {
                final message = effect.message ?? '';
                if (message.isEmpty) {
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
                return;
              }

              if (effect.type ==
                  CrashRecoveryEffectType.showUnfinishedRecording) {
                final record = effect.record;
                final languageName = effect.languageDisplayName;
                if (record == null || languageName == null) {
                  return;
                }

                await context.showUnfinishedRecordingDialog(
                  record: record,
                  languageDisplayName: languageName,
                  onDiscard: () {
                    final completer = Completer<void>();
                    _crashRecoveryBloc.add(
                      CrashRecoveryDiscardRequested(
                        pendingId: record.id,
                        deleteFile: true,
                        completer: completer,
                      ),
                    );
                    return completer.future;
                  },
                  onUpload: () {
                    final completer = Completer<void>();
                    _crashRecoveryBloc.add(
                      CrashRecoveryUploadRequested(
                        record: record,
                        completer: completer,
                      ),
                    );
                    return completer.future;
                  },
                );
              }
            },
          ),
        ],
        child: BlocBuilder<PendingUploadBloc, PendingUploadState>(
          builder: (context, uploadState) {
            return BlocBuilder<RecordSessionCubit, RecordSessionState>(
              builder: (context, recordState) {
                final showRecordingFloating =
                    recordState.hasSession && recordState.minimized;

                final showUploadFloating =
                    !showRecordingFloating &&
                    uploadState.activeUploadId != null;

                if (!showRecordingFloating && !showUploadFloating) {
                  return widget.child;
                }

                final blinkOn =
                    showRecordingFloating &&
                    recordState.isRecording &&
                    DateTime.now().second.isEven;

                return CustomerRecordFloatingOverlay(
                  floatingWidget: CustomerRecordFloatingBadge(
                    onTap: () async {
                      if (showRecordingFloating) {
                        await _recordSessionCubit.restoreSheet();
                        return;
                      }
                    },
                    child: showRecordingFloating
                        ? CustomerRecordRecordingBadgeContent(
                            blinkOn: blinkOn,
                            elapsedText: formatMmss(recordState.elapsed),
                          )
                        : CustomerRecordUploadBadgeContent(
                            progress: uploadState.activeProgress,
                          ),
                  ),
                  child: widget.child,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
