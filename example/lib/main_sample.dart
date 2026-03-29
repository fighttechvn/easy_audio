import 'dart:async';
import 'dart:developer';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import 'core/di/record_flow_injector.dart';
import 'data/datasources/fake_server_store.dart';
import 'presentation/record_session_flow/record_floating_overlay_host.dart';
import 'presentation/record_session_flow/sample_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await configureDependencies();

      final pendingUploadOrchestratorBloc = injector
          .get<PendingUploadOrchestratorBloc>();
      final fakeServerStore = injector.get<FakeServerStore>();
      pendingUploadOrchestratorBloc.setUploadRecordingProgressCallback(
        fakeServerStore.uploadAndPersistCopy,
      );

      runApp(const EasyAudioRecordSessionFlowExampleApp());
    },
    (error, trace) {
      log('------------------------------------');
      log('[AppDelegate]');
      log('$error');
      log('$trace');
      log('------------------------------------');
    },
  );
}

class EasyAudioRecordSessionFlowExampleApp extends StatefulWidget {
  const EasyAudioRecordSessionFlowExampleApp({super.key});

  @override
  State<EasyAudioRecordSessionFlowExampleApp> createState() =>
      _EasyAudioRecordSessionFlowExampleAppState();
}

class _EasyAudioRecordSessionFlowExampleAppState
    extends State<EasyAudioRecordSessionFlowExampleApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _fakeServerStore = injector.get<FakeServerStore>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    injector.reset(dispose: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: RecordFloatingOverlayHost(
        navigatorKey: _navigatorKey,
        child: SampleScreen(serverStore: _fakeServerStore),
      ),
    );
  }
}
