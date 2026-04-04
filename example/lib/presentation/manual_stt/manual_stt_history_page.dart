import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/history_item.dart';

class ManualSttHistoryPage extends StatefulWidget {
  const ManualSttHistoryPage({super.key});

  @override
  State<ManualSttHistoryPage> createState() => _ManualSttHistoryPageState();
}

class _ManualSttHistoryPageState extends State<ManualSttHistoryPage> {
  late final ManualSttController _controller;

  final ScrollController _liveTextScrollController = ScrollController();
  Timer? _elapsedTimer;
  DateTime? _sttStartedAt;
  Duration _sttDuration = Duration.zero;

  ManualSttState _state = ManualSttState.stopped;
  String _text = '';
  double _soundLevelProgress = 0.0;

  final List<HistoryItem> _history = <HistoryItem>[];
  bool _commitHistoryOnStopped = false;

  @override
  void initState() {
    super.initState();

    _controller = ManualSttController(context)
      ..listen(
        onListeningStateChanged: _onStateChanged,
        onListeningTextChanged: _onTextChanged,
        onSoundLevelChanged: _onSoundLevelChanged,
      )
      ..handlePermanentlyDeniedPermission(() {
        if (!mounted) {
          return;
        }
        _showPermissionSettingsSnackBar();
      });

    _controller.pauseIfMuteFor = const Duration(minutes: 3);

    // Optional defaults you may want to tweak:
    // _controller.clearTextOnStart = true;
    // _controller.localId = 'vi-VN';
    // _controller.enableHapticFeedback = true;
    // _controller.pauseIfMuteFor = const Duration(seconds: 10);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _liveTextScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _sttStartedAt;
      if (!mounted || startedAt == null) {
        return;
      }

      setState(() {
        _sttDuration = DateTime.now().difference(startedAt);
      });
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void _scrollLiveTextToBottom() {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_liveTextScrollController.hasClients) {
        return;
      }

      _liveTextScrollController.animateTo(
        _liveTextScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  void _onStateChanged(ManualSttState next) {
    final shouldCommit =
        next == ManualSttState.stopped && _commitHistoryOnStopped;
    final textToCommit = shouldCommit ? _text.trim() : null;

    if (shouldCommit) {
      _commitHistoryOnStopped = false;
    }

    setState(() {
      _state = next;

      if (next == ManualSttState.stopped) {
        final startedAt = _sttStartedAt;
        if (startedAt != null) {
          _sttDuration = DateTime.now().difference(startedAt);
        }
        _stopElapsedTimer();
      }

      if (textToCommit != null && textToCommit.isNotEmpty) {
        _history.insert(
          0,
          HistoryItem(timestamp: DateTime.now(), text: textToCommit),
        );
      }
    });
  }

  void _onTextChanged(String recognizedText) {
    final previousLength = _text.length;

    setState(() {
      _text = recognizedText;
    });

    if (recognizedText.length > previousLength) {
      _scrollLiveTextToBottom();
    }
  }

  void _onSoundLevelChanged(double level) {
    setState(() {
      _soundLevelProgress = _normalizeSoundLevel(level);
    });
  }

  double _normalizeSoundLevel(double level) {
    if (level.isNaN || level.isInfinite) {
      return 0.0;
    }

    // Some implementations report 0..1, others can be higher (e.g. ~0..10).
    final normalized = level > 1.0 ? (level / 10.0) : level;
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  Future<void> _safeAction(FutureOr<void> Function() action) async {
    try {
      final result = action();
      if (result is Future) {
        await result;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech-to-text error: $e')),
      );
    }
  }

  Future<void> _start() async {
    final granted = await _ensureSttPermissions();
    if (!granted) {
      return;
    }

    setState(() {
      _sttStartedAt = DateTime.now();
      _sttDuration = Duration.zero;
    });
    _startElapsedTimer();

    await _safeAction(() {
      try {
        _controller.startStt();
      } catch (e) {
        _stopElapsedTimer();
        if (mounted) {
          setState(() {
            _sttStartedAt = null;
            _sttDuration = Duration.zero;
          });
        }
        rethrow;
      }
    });
  }

  Future<void> _pauseOrResume() {
    if (_state == ManualSttState.listening) {
      return _safeAction(_controller.pauseStt);
    }
    if (_state == ManualSttState.paused) {
      return _safeAction(_controller.resumeStt);
    }
    return Future.value();
  }

  Future<void> _stop() {
    _commitHistoryOnStopped = true;
    return _safeAction(_controller.stopStt);
  }

  Future<bool> _ensureSttPermissions() async {
    if (kIsWeb) {
      return true;
    }

    final permissions = <Permission>[Permission.microphone];
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      permissions.add(Permission.speech);
    }

    final statuses = await permissions.request();
    final allGranted = statuses.values.every((s) => s.isGranted);
    if (allGranted) {
      return true;
    }

    final permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
    if (!mounted) {
      return false;
    }

    if (permanentlyDenied) {
      _showPermissionSettingsSnackBar();
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission is required for speech-to-text.'),
      ),
    );
    return false;
  }

  void _showPermissionSettingsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Microphone permission is required. Please enable it in Settings.',
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canStart = _state == ManualSttState.stopped;
    final canPauseOrResume =
        _state == ManualSttState.listening || _state == ManualSttState.paused;
    final canStop = _state != ManualSttState.stopped;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Speech-to-Text'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'State: ${_state.name}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${formatDurationTohhmmss(_sttDuration)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _soundLevelProgress),
                    const SizedBox(height: 4),
                    Text(
                      'Sound level',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canStart ? _start : null,
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canPauseOrResume ? _pauseOrResume : null,
                    icon: Icon(
                      _state == ManualSttState.paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(
                      _state == ManualSttState.paused ? 'Resume' : 'Pause',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canStop ? _stop : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Live text', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    controller: _liveTextScrollController,
                    child: SelectableText(
                      _text.isEmpty ? '—' : _text,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('History', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('No history yet'))
                  : ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.text),
                            subtitle: Text(
                              formatDateTimeTohhmmss(item.timestamp),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
