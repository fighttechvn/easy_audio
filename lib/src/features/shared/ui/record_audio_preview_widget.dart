import 'package:flutter/material.dart';

import '../../../core/utils/datetime_ext.dart';
import '../../../core/utils/duration_ext.dart';
import '../../../domain/entities/audio_playback_snapshot.dart';
import '../services/audio_playback_manager.dart';

class RecordAudioPreviewWidget extends StatefulWidget {
  const RecordAudioPreviewWidget({
    super.key,
    required this.source,
    this.title,
    this.createdAt,
  });

  final String source;
  final String? title;
  final DateTime? createdAt;

  @override
  State<RecordAudioPreviewWidget> createState() =>
      _RecordAudioPreviewWidgetState();
}

class _RecordAudioPreviewWidgetState extends State<RecordAudioPreviewWidget> {
  Duration? _dragPosition;

  AudioPlaybackManager get _playback => AudioPlaybackManager.instance;

  @override
  void dispose() {
    final src = widget.source;
    if (src.isNotEmpty) {
      final snap = _playback.snapshot.value;
      if (snap.currentUrl == src) {
        _playback.stop();
      }
    }
    super.dispose();
  }

  void _onDrag(double valueMs) {
    setState(() {
      _dragPosition = Duration(milliseconds: valueMs.toInt());
    });
  }

  Future<void> _onDragEnd(double valueMs) async {
    final src = widget.source;
    if (src.isEmpty) {
      setState(() => _dragPosition = null);
      return;
    }

    if (_playback.snapshot.value.currentUrl == src) {
      await _playback.seek(Duration(milliseconds: valueMs.toInt()));
    }

    if (mounted) {
      setState(() => _dragPosition = null);
    }
  }

  Future<void> _toggle(bool isActive, bool isPlaying) async {
    final src = widget.source;
    if (src.isEmpty) {
      return;
    }

    if (isActive && isPlaying) {
      await _playback.stop(clearUrl: false);
      return;
    }

    await _playback.playSource(src);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<AudioPlaybackSnapshot>(
      valueListenable: _playback.snapshot,
      builder: (context, snap, _) {
        final src = widget.source;
        final isActive = src.isNotEmpty && snap.currentUrl == src;
        final isPlaying = isActive && snap.isPlaying;
        final isLoading = isActive && snap.isLoading;

        final duration =
            isActive ? (snap.duration ?? Duration.zero) : Duration.zero;
        final position =
            isActive ? (_dragPosition ?? snap.position) : Duration.zero;

        final maxMs = duration.inMilliseconds.toDouble();
        final sliderMax = maxMs > 0 ? maxMs : 1.0;
        final sliderValue = maxMs > 0
            ? position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble()
            : 0.0;

        final subtitleParts = <String>[];
        final createdAt = widget.createdAt;
        if (createdAt != null) {
          subtitleParts.add(createdAt.showConfirmBooking);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((widget.title ?? '').trim().isNotEmpty)
              Text(
                widget.title!.trim(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(
                'Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitleParts.join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Slider(
              value: sliderValue,
              min: 0.0,
              max: sliderMax,
              onChanged: isActive && maxMs > 0 ? _onDrag : null,
              onChangeEnd: isActive && maxMs > 0 ? _onDragEnd : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Duration(milliseconds: sliderValue.toInt()).mmss,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  duration.mmss,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: (src.isEmpty || isLoading)
                    ? null
                    : () => _toggle(isActive, isPlaying),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(
                  isLoading ? 'Loading' : (isPlaying ? 'Stop' : 'Play'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
