import 'dart:async';
import 'dart:io';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/datetime_utils.dart';
import 'widgets/record_bottom_bar.dart';
import 'widgets/recording_detail_sheet.dart';

class SampleScreen extends StatefulWidget {
  const SampleScreen({super.key});

  @override
  State<SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<SampleScreen> {
  final easyAudio = EasyAudioService();
  String? selectedLocaleId;

  final List<RecordingResult> _items = <RecordingResult>[];
  bool _openingSheet = false;

  Future<void> _openRecordingDetail(RecordingResult item) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RecordingDetailSheet(item: item),
    );
  }

  Future<void> _initialAudio() async {
    if (!easyAudio.isInitialized) {
      try {
        final String fallbackLocaleId = Localizations.localeOf(
          context,
        ).toLanguageTag();
        await easyAudio.initialize(
          EasyAudioConfig(
            mode: EasyAudioMode.realtime,
            locale: selectedLocaleId ?? fallbackLocaleId,
          ),
        );

        if (!mounted) {
          return;
        }
      } catch (e, trace) {
        if (kDebugMode) {
          print(e);
          print(trace);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot initialize audio recorder.')),
          );
        }
      }
    }
  }

  Future<void> _onTapRecordButton() async {
    if (_openingSheet) {
      return;
    }

    setState(() {
      _openingSheet = true;
    });

    try {
      await _initialAudio();

      if (!mounted) {
        return;
      }

      final selection = await context.openSelectLanguages(easyAudio);
      if (!mounted) {
        return;
      }
      if (selection == null) {
        return;
      }
      selectedLocaleId = selection.localeId;
      final String fallbackLocaleId = Localizations.localeOf(
        context,
      ).toLanguageTag();
      final localeId = selectedLocaleId ?? fallbackLocaleId;

      if (!mounted) {
        return;
      }

      final result = await showModalBottomSheet<RecordingResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: true,
        builder: (context) {
          return RecordAudioBottomSheetWidget(
            easyAudio: easyAudio,
            localeId: localeId,
            enableAndroidBackgroundRecording: Platform.isAndroid,
          );
        },
      );

      if (kDebugMode) {
        print('[RecordSample] record: result $result');
      }

      if (!mounted || result == null) {
        return;
      }

      setState(() {
        _items.insert(0, result);
      });
    } finally {
      if (mounted) {
        setState(() {
          _openingSheet = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialAudio();
      }
    });
  }

  @override
  void dispose() {
    unawaited(() async {
      try {
        await AudioPlaybackManager.instance.stop(clearUrl: true);
      } catch (e, trace) {
        if (kDebugMode) {
          print(e);
          print(trace);
        }
      }

      for (final item in _items) {
        final filePath = item.filePath?.trim() ?? '';
        if (filePath.isEmpty) {
          continue;
        }
        try {
          await File(filePath).delete();
        } catch (_) {
          // best-effort
        }
      }
    }());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recordings ($selectedLocaleId)'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: () {
                context.openSelectLanguages(easyAudio).then((v) {
                  if (v != null) {
                    selectedLocaleId = v.localeId;
                    easyAudio
                        .updateConfig(
                          EasyAudioConfig(
                            mode: EasyAudioMode.realtime,
                            locale: selectedLocaleId,
                          ),
                        )
                        .then((_) {
                          setState(() {});
                        });
                  }
                });
              },
              child: const Icon(Icons.language),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? Center(
                child: Text(
                  'No recordings yet.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final RecordingResult item = _items[index];
                  final String transcript = item.transcript?.trim() ?? '';

                  final metaParts = <String>[item.formattedDuration];
                  final fileSize = item.formattedFileSize;
                  if (fileSize != null && fileSize.isNotEmpty) {
                    metaParts.add(fileSize);
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      onTap: () {
                        unawaited(_openRecordingDetail(item));
                      },
                      title: Text(DateTimeUtils.formatDateTime(item.endTime)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(metaParts.join(' • ')),
                          if (transcript.isNotEmpty)
                            Text(
                              transcript,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: RecordBottomBar(
        onTapRecord: _onTapRecordButton,
      ),
    );
  }
}
