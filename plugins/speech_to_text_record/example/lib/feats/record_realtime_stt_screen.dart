// ---------------------------------------------------------------------------
// Record + Realtime STT screen
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

class CombinedPipelineScreen extends StatefulWidget {
  const CombinedPipelineScreen({super.key});

  @override
  State<CombinedPipelineScreen> createState() => _CombinedPipelineScreenState();
}

class _CombinedPipelineScreenState extends State<CombinedPipelineScreen> {
  SpeechToTextRecordSession? _session;
  final List<String> _finalSegments = <String>[];
  String _partialSegment = '';
  String _selectedLocale = RecordLanguage.defaultLocale;
  bool _isRunning = false;
  bool _isPreparing = false;
  bool _recordingEnabled = false;
  bool _isPlaying = false;
  String? _activeFilePath;
  String? _lastSavedFile;
  String? _error;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final bool playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
    unawaited(_configureAudioSession());
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> _startPipeline() async {
    if (_isRunning || _isPreparing) {
      return;
    }
    final previousSession = _session;
    if (previousSession != null) {
      _session = null;
      unawaited(previousSession.dispose());
    }
    setState(() {
      _isPreparing = true;
      _error = null;
      _finalSegments.clear();
      _partialSegment = '';
      _lastSavedFile = null;
    });
    try {
      final session = await SpeechToTextRecord.startCombined(
        sampleRate: 16000,
        localeId: _selectedLocale,
        onResult: _handleTranscript,
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) {
            return;
          }
          setState(() => _error = error.toString());
        },
      );
      if (!mounted) {
        await session.dispose();
        return;
      }
      setState(() {
        _session = session;
        _isRunning = true;
        _isPreparing = false;
        _recordingEnabled = session.recordingEnabled;
        _activeFilePath = session.recordingPath;
        _error = null;
      });
    } on SpeechToTextNotSupportedException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _error = error.toString();
      });
    } on MicrophonePermissionException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _error = error.toString();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _stopPipeline({bool discardRecording = false}) async {
    final session = _session;
    if (session == null) {
      return;
    }
    String? savedPath;
    final bool recordingEnabled = session.recordingEnabled;
    try {
      savedPath = await session.stop(discardRecording: discardRecording);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      await session.dispose();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _session = null;
      _isRunning = false;
      _isPreparing = false;
      _recordingEnabled = recordingEnabled;
      _activeFilePath = null;
      _lastSavedFile = discardRecording ? null : savedPath;
      _partialSegment = '';
    });
  }

  void _handleTranscript(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      if (result.isFinal) {
        _finalSegments.add(result.text);
        _partialSegment = '';
      } else {
        _partialSegment = result.text;
      }
    });
  }

  Future<void> _playLastRecording() async {
    final String? path = _lastSavedFile;
    if (path == null) {
      return;
    }
    if (_isPlaying) {
      await _player.stop();
      return;
    }
    try {
      await _player.setFilePath(path);
      await _player.play();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể phát tệp đã ghi: $error';
      });
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(session.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = <String>[
      'Pipeline: ${_isRunning
          ? 'đang chạy'
          : _isPreparing
          ? 'đang khởi động'
          : 'đã dừng'}',
      if (_recordingEnabled)
        'Ghi âm: ${_isRunning ? 'đang ghi' : 'đã dừng'}'
      else
        'Ghi âm: không khả dụng trong chế độ đồng thời',
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Record + STT')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(statusText),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngôn ngữ',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLocale,
                      isExpanded: true,
                      onChanged: _isRunning || _isPreparing
                          ? null
                          : (String? value) {
                              if (value == null) return;
                              setState(() => _selectedLocale = value);
                            },
                      items: RecordLanguage.supported.values
                          .map(
                            (locale) => DropdownMenuItem<String>(
                              value: locale,
                              child: Text(RecordLanguage.labelFor(locale)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: _isRunning || _isPreparing
                        ? null
                        : _startPipeline,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start pipeline'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isRunning
                        ? () => _stopPipeline(discardRecording: false)
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop & keep file'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isRunning
                        ? () => _stopPipeline(discardRecording: true)
                        : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop & discard'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _lastSavedFile != null && !_isRunning
                        ? _playLastRecording
                        : null,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _isPlaying ? 'Stop playback' : 'Play last recording',
                    ),
                  ),
                ],
              ),
              if (_isRunning && !_recordingEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Lưu ý: iOS khóa micro khi đang nhận diện giọng nói, ghi âm sẽ tạm thời bị vô hiệu.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Real-time transcription',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: <Widget>[
                      for (final String segment in _finalSegments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(segment),
                        ),
                      if (_partialSegment.isNotEmpty)
                        Text(
                          _partialSegment,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                    ],
                  ),
                ),
              ),
              if (_activeFilePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Đang ghi vào: $_activeFilePath'),
                ),
              if (_lastSavedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Tệp đã lưu: $_lastSavedFile'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
