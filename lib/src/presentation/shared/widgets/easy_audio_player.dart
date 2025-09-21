import 'package:flutter/material.dart';

import '../../../core/services/easy_audio_controller.dart';
import '../../../domain/entities/process_player.dart';

const kSizeEasyAudioPlayer = 150.0;
typedef BuilderSlider = Widget Function(
    Duration? duration, Duration? posision, bool isLoadDone);
typedef FormatTimeSlider = String Function(Duration duration);

class EasyAudioPlayer extends StatefulWidget {
  const EasyAudioPlayer({
    super.key,
    required this.controller,
    this.loading,
    this.buttonStop,
    this.formatTimeSlider,
    required this.builderSlider,
  });

  final EasyAudioController controller;
  final BuilderSlider builderSlider;
  final FormatTimeSlider? formatTimeSlider;
  final Widget? loading;
  final Widget? buttonStop;

  @override
  State<EasyAudioPlayer> createState() => _EasyAudioPlayerState();
}

class _EasyAudioPlayerState extends State<EasyAudioPlayer> {
  EasyAudioController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kSizeEasyAudioPlayer,
      width: MediaQuery.of(context).size.width,
      child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final isLoading =
                controller.isOpenPlayer && controller.isPlaying == false;

            return Column(
              children: [
                ValueListenableBuilder<ProcessPlayer>(
                  valueListenable: controller.onProgress,
                  builder: (_, data, __) {
                    var duration = '00:00';
                    var position = '00:00';

                    if (!isLoading &&
                        data.duration != null &&
                        data.position != null) {
                      duration = widget.formatTimeSlider != null
                          ? widget.formatTimeSlider!(data.duration!)
                          : data.duration.toString();
                      position = widget.formatTimeSlider != null
                          ? widget.formatTimeSlider!(data.position!)
                          : data.position.toString();
                    }

                    return Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 65,
                            child: widget.builderSlider(
                              data.duration,
                              data.position,
                              !isLoading,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(position),
                                const Spacer(),
                                Text(duration),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 0),
                    child: isLoading || !controller.isPlaying
                        ? SizedBox(
                            width: 40,
                            height: 40,
                            child: widget.loading ??
                                const CircularProgressIndicator(),
                          )
                        : GestureDetector(
                            onTap: () => controller.play(),
                            child: Center(
                              child: widget.buttonStop ??
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(40.0),
                                    ),
                                    child: const Icon(
                                      Icons.stop,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                  ),
                )
              ],
            );
          }),
    );
  }
}
