import 'package:flutter/material.dart';

import '../../../core/services/easy_audio_controller.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/process_player.dart';

/// Simple audio player widget that manages its own controller.
///
/// This is a self-contained widget for playing audio files.
/// Just pass a URL and it works! No need to manage controllers externally.
///
/// ## Usage
///
/// ```dart
/// SimpleAudioPlayer(
///   url: 'path/to/audio.m4a',
///   title: 'My Recording',
///   expanded: true,
/// ),
/// ```
///
/// ## Features
///
/// - Play/pause button
/// - Seek forward/backward 5 seconds
/// - Progress slider with drag-to-seek
/// - Duration and position display
/// - Expandable/collapsible UI
///
/// ## Customization
///
/// For more control over the player UI, use [EasyAudioPlayer] directly
/// with your own [EasyAudioController].
class SimpleAudioPlayer extends StatefulWidget {
  /// Audio file URL (can be local path or remote URL).
  final String url;

  /// Optional title to display.
  final String? title;

  /// Optional created date to display.
  final DateTime? createdAt;

  /// Whether to expand by default.
  final bool expanded;

  /// Callback when play button is tapped.
  final VoidCallback? onPlay;

  /// Custom play button builder.
  final Widget Function(
          BuildContext context, bool isPlaying, VoidCallback onTap)?
      playButtonBuilder;

  const SimpleAudioPlayer({
    super.key,
    required this.url,
    this.title,
    this.createdAt,
    this.expanded = false,
    this.onPlay,
    this.playButtonBuilder,
  });

  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  late final EasyAudioController _controller;
  bool _isExpanded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded;
    _controller = EasyAudioController.withBackgroundMode();
    _initController();
  }

  Future<void> _initController() async {
    await _controller.initPlayer();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.isPlaying && _controller.url == widget.url) {
      _controller.stopPlayer();
    } else {
      _controller.play(widget.url);
      widget.onPlay?.call();
    }
  }

  void _seekBackward() {
    final position = _controller.onProgress.value.position;
    if (position != null) {
      _controller.seek(position - const Duration(seconds: 5));
    }
  }

  void _seekForward() {
    final position = _controller.onProgress.value.position;
    if (position != null) {
      _controller.seek(position + const Duration(seconds: 5));
    }
  }

  void _onSliderChanged(double value) {
    _controller.seek(Duration(milliseconds: value.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isActive = widget.url == _controller.url;
        final isPlaying = _controller.isPlaying && isActive;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? 'Audio',
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (widget.createdAt != null)
                            Text(
                              FormatUtils.formatDate(widget.createdAt!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_less),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable content
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Progress slider
                          ValueListenableBuilder<ProcessPlayer>(
                            valueListenable: _controller.onProgress,
                            builder: (context, progress, child) {
                              final position =
                                  isActive ? progress.position : Duration.zero;
                              final duration =
                                  isActive ? progress.duration : Duration.zero;

                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      trackHeight: 4,
                                      activeTrackColor:
                                          theme.colorScheme.primary,
                                      inactiveTrackColor: theme
                                          .colorScheme.onSurface
                                          .withValues(alpha: 0.2),
                                      thumbColor: theme.colorScheme.primary,
                                    ),
                                    child: Slider(
                                      value: (position?.inMilliseconds ?? 0)
                                          .toDouble()
                                          .clamp(
                                              0,
                                              (duration?.inMilliseconds ?? 0)
                                                  .toDouble()),
                                      min: 0,
                                      max: (duration?.inMilliseconds ?? 1)
                                          .toDouble(),
                                      onChanged: _onSliderChanged,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        FormatUtils.formatDuration(position),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      Text(
                                        FormatUtils.formatDuration(duration),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          // Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _seekBackward,
                                icon: const Icon(Icons.replay_5),
                                tooltip: 'Rewind 5 seconds',
                              ),
                              const SizedBox(width: 16),
                              if (!_isInitialized)
                                const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              else if (widget.playButtonBuilder != null)
                                widget.playButtonBuilder!(
                                  context,
                                  isPlaying,
                                  _togglePlayPause,
                                )
                              else
                                IconButton(
                                  onPressed: _togglePlayPause,
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    size: 48,
                                  ),
                                  tooltip: isPlaying ? 'Pause' : 'Play',
                                ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: _seekForward,
                                icon: const Icon(Icons.forward_5),
                                tooltip: 'Forward 5 seconds',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
