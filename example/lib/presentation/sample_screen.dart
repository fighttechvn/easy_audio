import 'dart:async';
import 'dart:io';

import 'package:easy_audio/easy_audio.dart';
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
  final List<RecordingResult> _items = <RecordingResult>[];
  bool _openingSheet = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    unawaited(() async {
      try {
        await AudioPlaybackManager.instance.stop(clearUrl: true);
      } catch (_) {}

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

  Future<void> _onTapRecordButton() async {
    if (_openingSheet) {
      return;
    }

    setState(() {
      _openingSheet = true;
    });

    try {
      final easyAudio = EasyAudioService();
      final fallbackLocaleId = Localizations.localeOf(context).toLanguageTag();

      if (!easyAudio.isInitialized) {
        try {
          await easyAudio.initialize(
            const EasyAudioConfig(mode: EasyAudioMode.realtime),
          );

          if (!mounted) {
            return;
          }
        } catch (_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot initialize audio recorder.')),
          );
          return;
        }
      }

      String? selectedLocaleId;

      if (Platform.isIOS) {
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
      }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recordings')),
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
      bottomNavigationBar: RecordBottomBar(onTapRecord: _onTapRecordButton),
    );
  }
}
