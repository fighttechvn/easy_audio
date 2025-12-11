// ---------------------------------------------------------------------------
// Record-only screen
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

class RecordOnlyScreen extends StatefulWidget {
  const RecordOnlyScreen({super.key});

  @override
  State<RecordOnlyScreen> createState() => _RecordOnlyScreenState();
}

class _RecordOnlyScreenState extends State<RecordOnlyScreen> {
  final SimpleAudioRecorder _recorder = SimpleAudioRecorder();
  bool _isRecording = false;
  String? _lastFile;
  String? _error;

  Future<void> _startRecording() async {
    try {
      final path = await _recorder.start();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _lastFile = path;
        _error = null;
      });
    } on MicrophonePermissionException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _lastFile = path ?? _lastFile;
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record audio only')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Trạng thái: ${_isRecording ? 'Đang ghi' : 'Đã dừng'}'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(_isRecording ? 'Stop recording' : 'Start recording'),
            ),
            const SizedBox(height: 16),
            if (_lastFile != null) Text('Tệp gần nhất: $_lastFile'),
          ],
        ),
      ),
    );
  }
}
