import 'package:flutter/material.dart';

import 'feats/playback_screen.dart';
import 'feats/record_realtime_stt_screen.dart';
import 'feats/record_screen.dart';
import 'feats/stt_screen.dart' show SpeechToTextOnlyScreen;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeechToTextRecordDemo());
}

class SpeechToTextRecordDemo extends StatelessWidget {
  const SpeechToTextRecordDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech to Text Record Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const FeatureListPage(),
    );
  }
}

class FeatureListPage extends StatelessWidget {
  const FeatureListPage({super.key});

  static final List<_FeatureEntry> _features = <_FeatureEntry>[
    _FeatureEntry(
      title: 'Record + Realtime STT',
      description:
          'Unified pipeline gửi audio đến cả bộ nhận dạng và bộ ghi file.',
      builder: (BuildContext context) => const CombinedPipelineScreen(),
    ),
    _FeatureEntry(
      title: 'Record audio',
      description: 'Sử dụng package record để lưu WAV vào thư mục Documents.',
      builder: (BuildContext context) => const RecordOnlyScreen(),
    ),
    _FeatureEntry(
      title: 'Speech to Text',
      description:
          'Chỉ chạy nhận dạng giọng nói theo thời gian thực và hiển thị bản ghi.',
      builder: (BuildContext context) => const SpeechToTextOnlyScreen(),
    ),
    _FeatureEntry(
      title: 'Play recordings',
      description: 'Danh sách các file WAV đã lưu và cho phép phát lại.',
      builder: (BuildContext context) => const PlaybackScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech to Text Record Demo')),
      body: ListView.separated(
        itemCount: _features.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final entry = _features[index];
          return ListTile(
            title: Text(entry.title),
            subtitle: Text(entry.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: entry.builder)),
          );
        },
      ),
    );
  }
}

class _FeatureEntry {
  const _FeatureEntry({
    required this.title,
    required this.description,
    required this.builder,
  });

  final String title;
  final String description;
  final WidgetBuilder builder;
}
