import 'package:flutter/material.dart';

import 'core/di/record_flow_deps.dart';
import 'core/di/record_flow_injector.dart';
import 'presentation/record_session_flow/customer_record_flow_demo_screen.dart';
import 'presentation/record_session_flow/record_floating_overlay_host.dart';

/// Run this example with:
/// `flutter run -t lib/main_record_session_flow.dart`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EasyAudioRecordSessionFlowExampleApp());
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

  late final RecordFlowDeps _deps;

  @override
  void initState() {
    super.initState();
    configureRecordFlowInjector();
    _deps = injector.get<RecordFlowDeps>();
  }

  @override
  void dispose() {
    _deps.dispose();
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
        child: CustomerRecordFlowDemoScreen(serverStore: _deps.fakeServerStore),
      ),
    );
  }
}
