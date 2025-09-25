import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/record_data.dart';
import '../../record_audio_constants.dart';
import '../shared/widgets/waveforms_sound/fixed_wareform.dart';
import 'bloc/speech_text_bloc.dart';

class RecordModalWidget extends StatefulWidget {
  const RecordModalWidget({
    super.key,
    this.onExits,
    this.title,
    required this.locale,
  });

  final String? title;
  final Future<bool?> Function()? onExits;
  final String locale;

  @override
  State<RecordModalWidget> createState() => _RecordModalWidgetState();
}

class _RecordModalWidgetState extends State<RecordModalWidget> {
  Timer? _timer;
  final ValueNotifier<int> _elapsedSeconds = ValueNotifier<int>(0);
  final TextEditingController _textCtrl = TextEditingController();
  DateTime? _recordStartedAt;

  void _stopRecord(bool save) {
    context.read<SpeechTextBloc>().add(StopRecordEvent(isSave: save));
  }

  void _startPipeline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SpeechTextBloc>().add(
            StartRecordEvent(
              callbackToText: (text) => _textCtrl.text = text,
            ),
          );
    });
  }

  void _onListenerSpeechTextBloc(BuildContext context, SpeechTextState state) {
    if (state is InitFailed && state.stateUI.isCloseFeature) {
      Navigator.of(context).pop();
      return;
    }

    if (state is InitSucceeded) {
      _startPipeline();
    } else if (state is Recording) {
      if (_recordStartedAt == null) {
        _recordStartedAt = DateTime.now();
        _elapsedSeconds.value = 0;
      }
    } else if (state is StoppedRecord) {
      _recordStartedAt = null;
      if (!state.isSave) {
        Navigator.of(context).pop();
        return;
      }

      final filePath = state.filePath;
      if (filePath == null) {
        if (state.recordingAvailable == false && mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Recording unavailable on this platform.'),
            ),
          );
        }
        Navigator.of(context).pop();
        return;
      }

      final record = RecordData(
        createdAt: DateTime.now(),
        url: filePath,
        totalTime: state.recordedDuration,
        content: _textCtrl.text,
      );

      if (context.mounted) {
        Navigator.of(context).pop(record);
      }
    } else if (state is RecordError) {
      _recordStartedAt = null;
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _onTapCloseButton() {
    if (widget.onExits != null) {
      widget.onExits?.call().then((value) {
        if (value == true) {
          _stopRecord(false);
        }
      });
    } else {
      _stopRecord(false);
    }
  }

  void _updateElapsedTimer(Timer timer) {
    final startedAt = _recordStartedAt;
    if (startedAt == null) {
      _elapsedSeconds.value = 0;
      return;
    }
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    _elapsedSeconds.value = elapsed;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateElapsedTimer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedSeconds.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? '[${widget.locale}] Transcripts: ';

    return GestureDetector(
      onTap: _onTapCloseButton,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.transparent,
        height: MediaQuery.of(context).size.height,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: BlocConsumer<SpeechTextBloc, SpeechTextState>(
            listener: _onListenerSpeechTextBloc,
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                      blurRadius: 1.0,
                      offset: const Offset(0, -1),
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                height: 350,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            maxLines: 6,
                            controller: _textCtrl,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _onTapCloseButton,
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _elapsedSeconds,
                            builder: (_, sec, __) {
                              return Text(
                                Duration(seconds: sec).formatTimeAudio,
                              );
                            },
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _stopRecord(true),
                          icon: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Expanded(
                      child: Center(
                        child: SizedBox(
                          height: 150,
                          child: AnimatedWaveform(divide: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
