import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

class RecordingDetailSheet extends StatelessWidget {
  const RecordingDetailSheet({
    super.key,
    required this.item,
  });

  final RecordingResult item;

  String _formatDateTime(DateTime dt) {
    final t = dt.toLocal();
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$m/$d/$y $hh:$mm:$ss';
  }

  String _sourceFor(RecordingResult r) {
    final filePath = r.filePath?.trim() ?? '';
    if (filePath.isEmpty) {
      return '';
    }
    return Uri.file(filePath).toString();
  }

  Future<void> _ensurePlaybackAudioSessionActive() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _togglePlay(BuildContext context) async {
    final source = _sourceFor(item);
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio file for this recording.')),
      );
      return;
    }

    final filePath = item.filePath?.trim() ?? '';
    if (filePath.isNotEmpty && !File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file not found.')),
      );
      return;
    }

    await _ensurePlaybackAudioSessionActive();
    if (!context.mounted) {
      return;
    }

    await AudioPlaybackManager.instance.toggleSource(source);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final transcript = (item.transcript ?? '').trim();
    final hasTranscript = transcript.isNotEmpty;

    final metaParts = <String>[item.formattedDuration];
    final fileSize = item.formattedFileSize;
    if (fileSize != null && fileSize.isNotEmpty) {
      metaParts.add(fileSize);
    }

    final source = _sourceFor(item);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatDateTime(item.endTime),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              metaParts.join(' • '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<AudioPlaybackSnapshot>(
              valueListenable: AudioPlaybackManager.instance.snapshot,
              builder: (context, snap, _) {
                final isActive = snap.currentUrl == source;
                final isPlaying = isActive && snap.isPlaying;

                return FilledButton.icon(
                  onPressed: source.isEmpty ? null : () => _togglePlay(context),
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(isPlaying ? 'Pause' : 'Play'),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Transcript', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Text(
                  hasTranscript ? transcript : 'No transcript.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
