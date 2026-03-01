import 'dart:async';
import 'dart:io';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/record_flow_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/datasources/fake_server_store.dart';
import '../../domain/entities/server_recording.dart';

class CustomerRecordFlowDemoScreen extends StatefulWidget {
  const CustomerRecordFlowDemoScreen({super.key, required this.serverStore});

  final FakeServerStore serverStore;

  @override
  State<CustomerRecordFlowDemoScreen> createState() =>
      _CustomerRecordFlowDemoScreenState();
}

class _CustomerRecordFlowDemoScreenState
    extends State<CustomerRecordFlowDemoScreen> {
  static const String _appointmentIdEmr = 'DEMO_EMR_001';
  static const int _appointmentId = 1;

  List<ServerRecording> _server = const <ServerRecording>[];
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
        _server = list;
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
            _pendingRecordingsBloc.add(
              const PendingRecordingsRefreshRequested(),
            );
            unawaited(_reloadServer());
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('All recordings (flow demo)')),
        body: SafeArea(
          child: BlocBuilder<PendingRecordingsBloc, PendingRecordingsState>(
            builder: (context, pendingState) {
              final pending = pendingState.uiState.items
                  .where(
                    (e) =>
                        e.appointmentIdEmr.trim() == _appointmentIdEmr.trim() &&
                        (e.userId == null || e.userId == recordFlowDemoUserId),
                  )
                  .toList(growable: false);

              return Column(
                children: [
                  if (_loadingServer)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        const _SectionHeader(
                          title: 'Uploaded (simulated server)',
                        ),
                        if (_server.isEmpty)
                          const _EmptyHint(text: 'No uploaded recordings yet.'),
                        for (final item in _server)
                          _ServerRecordingTile(recording: item),
                        const SizedBox(height: 8),
                        const _SectionHeader(title: 'Drafts (pending local)'),
                        if (pending.isEmpty)
                          const _EmptyHint(text: 'No draft recordings yet.'),
                        for (final record in pending)
                          PendingRecordCardWidget(
                            record: record,
                            progressFor: _pendingUploadBloc.progressFor,
                            enqueueUpload: (id) {
                              unawaited(_pendingUploadBloc.enqueue(id));
                            },
                            deletePendingRecording: (id, {deleteFile = false}) {
                              return _deletePendingRecording(
                                id,
                                deleteFile: deleteFile,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 12, top: 8),
          child: Center(
            child: GestureDetector(
              onTap: _onTapRecordButton,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerRecordingTile extends StatelessWidget {
  const _ServerRecordingTile({required this.recording});

  final ServerRecording recording;

  @override
  Widget build(BuildContext context) {
    final playback = AudioPlaybackManager.instance;

    return ValueListenableBuilder<AudioPlaybackSnapshot>(
      valueListenable: playback.snapshot,
      builder: (context, snap, _) {
        final isActive = snap.currentUrl == recording.source;
        final isPlaying = isActive && snap.isPlaying;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text('Audio ${formatDateTime(recording.createdAt)}'),
            subtitle: Text(formatBytes(recording.fileSizeBytes)),
            trailing: IconButton(
              onPressed: () async {
                await playback.toggleSource(recording.source);
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
