import 'dart:async';
import 'dart:io';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/record_flow_constants.dart';
import '../../data/datasources/fake_server_store.dart';
import '../../domain/entities/server_recording.dart';
import 'widgets/customer_record_flow_body.dart';
import 'widgets/record_bottom_bar.dart';

class SampleScreen extends StatefulWidget {
  const SampleScreen({
    super.key,
    required this.serverStore,
  });

  final FakeServerStore serverStore;

  @override
  State<SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<SampleScreen> {
  static const String _appointmentIdEmr = 'DEMO_EMR_001';
  static const int _appointmentId = 1;

  List<ServerRecording> _serverItems = const <ServerRecording>[];
  bool _loadingServer = false;

  RecordSessionCubit get _recordSessionCubit =>
      context.read<RecordSessionCubit>();
  PendingUploadBloc get _pendingUploadBloc => context.read<PendingUploadBloc>();
  PendingRecordingsBloc get _pendingRecordingsBloc =>
      context.read<PendingRecordingsBloc>();

  @override
  void initState() {
    super.initState();

    _pendingRecordingsBloc.add(const PendingRecordingsInitRequested());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordSessionCubit.maybeAutoOpenForAppointment(_appointmentIdEmr);
      unawaited(_reloadServer());
    });
  }

  Future<void> _reloadServer() async {
    if (_loadingServer) {
      return;
    }

    setState(() {
      _loadingServer = true;
    });

    try {
      final list = await widget.serverStore.listForAppointment(
        _appointmentIdEmr,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _serverItems = list;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingServer = false;
        });
      }
    }
  }

  Future<void> _deletePendingRecording(String id, {bool deleteFile = false}) {
    final completer = Completer<void>();
    _pendingRecordingsBloc.add(
      PendingRecordingsDeleteRequested(
        id: id,
        deleteFile: deleteFile,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> _onTapRecordButton() async {
    await AudioPlaybackManager.instance.stop();
    await _startOrResumeForAppointment();
  }

  Future<void> _startOrResumeForAppointment() async {
    final fallbackLocale = Localizations.localeOf(context).toLanguageTag();

    await _recordSessionCubit.ensureAudioInitialized();

    LanguageSelection? selection;

    if (Platform.isIOS &&
        mounted &&
        _recordSessionCubit.state.canReopen == false) {
      selection = await context.openSelectLanguages(
        _recordSessionCubit.easyAudio,
      );
      if (!mounted) {
        return;
      }
      if (selection == null) {
        return;
      }
    }

    final result = await _recordSessionCubit.startOrResumeForAppointment(
      appointmentIdEmr: _appointmentIdEmr,
      appointmentId: _appointmentId,
      userId: recordFlowDemoUserId,
      fallbackLocale: fallbackLocale,
      clinicName: 'Demo Clinic',
      patientName: 'Demo Patient',
      bookingDate: '02/28/2026',
      bookingTime: '09:00',
      localeId: selection?.localeId,
    );

    if (!mounted) {
      return;
    }

    if (result == RecordSessionStartResult.permissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
      );
      return;
    }

    if (result == RecordSessionStartResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start recording. Please try again.'),
        ),
      );
    }
  }

  List<PendingRecording> _filterPendingForThisDemo(
    List<PendingRecording> items,
  ) {
    final appointmentKey = _appointmentIdEmr.trim();
    return items
        .where(
          (e) =>
              e.appointmentIdEmr.trim() == appointmentKey &&
              ((e.userId == null) || (e.userId == recordFlowDemoUserId)),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RecordSessionCubit, RecordSessionState>(
          listenWhen: (prev, next) => prev.lastSavedAt != next.lastSavedAt,
          listener: (context, state) {
            _pendingRecordingsBloc.add(
              const PendingRecordingsRefreshRequested(),
            );
            unawaited(_reloadServer());
          },
        ),
        BlocListener<PendingUploadBloc, PendingUploadState>(
          listenWhen: (prev, next) => prev.lastResult != next.lastResult,
          listener: (context, state) {
            final result = state.lastResult;
            if (result == null) {
              return;
            }
            if (result.appointmentIdEmr.trim() != _appointmentIdEmr.trim()) {
              return;
            }

            // Upload finished for this appointment, reload the uploaded list.
            unawaited(() async {
              await _reloadServer();

              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  _pendingRecordingsBloc.add(
                    const PendingRecordingsRefreshRequested(),
                  );
                }
              });
            }());
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('All recordings')),
        body: SafeArea(
          child: BlocBuilder<PendingRecordingsBloc, PendingRecordingsState>(
            builder: (context, pendingState) {
              final allPending = pendingState.uiState.items;
              final pending = _filterPendingForThisDemo(allPending);

              return CustomerRecordFlowBody(
                loadingServer: _loadingServer,
                serverItems: _serverItems,
                allPendingCount: allPending.length,
                pendingItems: pending,
                progressFor: _pendingUploadBloc.progressFor,
                enqueueUpload: (id) {
                  unawaited(_pendingUploadBloc.enqueue(id));
                },
                deletePendingRecording: _deletePendingRecording,
              );
            },
          ),
        ),
        bottomNavigationBar: RecordBottomBar(onTapRecord: _onTapRecordButton),
      ),
    );
  }
}
