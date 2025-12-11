import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechSampleApp extends StatefulWidget {
  const SpeechSampleApp({super.key});

  @override
  State<SpeechSampleApp> createState() => _SpeechSampleAppState();
}

class _SpeechSampleAppState extends State<SpeechSampleApp> {
  SpeechToTextRecordSession? _session;
  bool _isPreparing = false;
  bool _isRunning = false;
  bool _recordingEnabled = false;
  String _transcript = '';
  String _partialTranscript = '';
  String? _activeRecordingPath;
  String? _lastSavedRecording;
  String? _lastError;
  late final AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _player.onPlayerComplete.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _ensurePermissions() async {
    final statuses =
        await <Permission>[Permission.microphone, Permission.speech].request();
    final granted = statuses.values.every((status) => status.isGranted);
    if (!granted) {
      throw Exception('Microphone or speech permission not granted.');
    }
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

    if (_isPlaying) {
      await _player.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }

    setState(() {
      _isPreparing = true;
      _lastError = null;
      _transcript = '';
      _partialTranscript = '';
      _activeRecordingPath = null;
      _lastSavedRecording = null;
    });

    try {
      await _ensurePermissions();
      final session = await SpeechToTextRecord.startCombined(
        onResult: (SpeechRecognitionResult result) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (result.isFinal) {
              if (result.text.trim().isNotEmpty) {
                _transcript = (_transcript.isEmpty
                        ? result.text
                        : '$_transcript ${result.text}')
                    .trim();
              }
              _partialTranscript = '';
            } else {
              _partialTranscript = result.text;
            }
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) {
            return;
          }
          setState(() {
            _lastError = error.toString();
          });
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
        _activeRecordingPath = session.recordingPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error.toString();
        _isPreparing = false;
        _isRunning = false;
        _recordingEnabled = false;
        _activeRecordingPath = null;
      });
    }
  }

  Future<void> _stopPipeline({required bool discardRecording}) async {
    final session = _session;
    if (session == null) {
      return;
    }

    String? savedPath;
    try {
      savedPath = await session.stop(discardRecording: discardRecording);
    } catch (error) {
      if (mounted) {
        setState(() {
          _lastError = error.toString();
        });
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
      _lastSavedRecording = discardRecording ? null : savedPath;
      if (discardRecording) {
        _activeRecordingPath = null;
      }
    });
  }

  Future<void> _togglePlayback() async {
    final savedPath = _lastSavedRecording;
    if (savedPath == null) {
      return;
    }

    if (_isPlaying) {
      await _player.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      return;
    }

    try {
      await _player.stop();
      await _player.play(DeviceFileSource(savedPath));
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = 'Playback failed: $error';
        _isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(session.dispose());
    }
    unawaited(_player.stop());
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canStart = !_isRunning && !_isPreparing;
    final bool canStop = _isRunning;
    final transcriptDisplay = [
      if (_transcript.isNotEmpty) _transcript,
      if (_partialTranscript.isNotEmpty) '$_partialTranscript…',
    ].join('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text Record'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Status: '),
                  Text(
                    _isPreparing
                        ? 'preparing'
                        : _isRunning
                            ? 'listening'
                            : 'idle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _recordingEnabled
                    ? 'Recording to: ${_activeRecordingPath ?? 'pending…'}'
                    : 'Recording disabled on this device',
              ),
              if (_lastSavedRecording != null) ...[
                const SizedBox(height: 8),
                Text('Last saved file: $_lastSavedRecording'),
              ],
              if (_lastError != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error: $_lastError',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      transcriptDisplay.isEmpty
                          ? 'Press start and speak to see transcripts here.'
                          : transcriptDisplay,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: canStart ? _startPipeline : null,
                      child: const Text('Start'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: canStop
                          ? () => _stopPipeline(discardRecording: false)
                          : null,
                      child: const Text('Stop & Save'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: canStop
                          ? () => _stopPipeline(discardRecording: true)
                          : null,
                      child: const Text('Stop & Discard'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed:
                          _lastSavedRecording != null ? _togglePlayback : null,
                      child: Text(_isPlaying ? 'Stop Playback' : 'Play Saved'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
