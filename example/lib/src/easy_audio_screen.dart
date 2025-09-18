import 'package:easy_audio/easy_audio.dart';
import 'package:example/src/constans.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'example/speech_to_text/main.dart';

class EasyAudioExampleScreen extends StatefulWidget {
  const EasyAudioExampleScreen({super.key});

  @override
  State<EasyAudioExampleScreen> createState() => _EasyAudioExampleScreenState();
}

class _EasyAudioExampleScreenState extends State<EasyAudioExampleScreen> {
  final EasyAudioController _audioController = EasyAudioController();

  var _offset = kOffsetHide;
  var _urlPlay = '';
  final _dataRecord = kMockDataRecord;

  Future<bool?> askPermission() async {
    // if (await Permission.contacts.request().isGranted) {
    //   // Either the permission was already granted before or the user just granted it.
    // }

    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.speech,
    ].request();

    return statuses[Permission.microphone] == PermissionStatus.granted &&
        statuses[Permission.speech] == PermissionStatus.granted;
  }

  void _onTapStartRecord() {
    askPermission().then((val) {
      if (val == true) {
        if (mounted) {
          context.startRecord().then((value) {
            if (value != null) {
              _dataRecord.add(value);
              setState(() {});
              // _playAudio(value.url);
            }
          });
        }
      }
    });
  }

  void _init() {
    _audioController.initPlayer(false);
    _audioController.addListener(() {
      if (_offset == kOffsetHide && _audioController.isOpenPlayer) {
        setState(() {
          _offset = kOffsetShow;
        });
      }
      if (_audioController.isPlaying == false) {
        setState(() {
          _offset = kOffsetHide;
        });
      }
    });
  }

  void _playAudio(String url) {
    final currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }

    setState(() {
      _urlPlay = url;
      _audioController.play(_urlPlay);
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _audioController.forceDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sizeBottom = 110.0;
    final isShowBottom =
        MediaQuery.of(context).viewInsets.bottom == 0 && _offset == kOffsetShow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Audio'),
        actions: [
          IconButton(
            onPressed: () {
              context.startSelectLanguagueDialog();
            },
            icon: const Icon(Icons.language),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SpeechSampleApp(),
                ),
              );
            },
            icon: const Icon(Icons.record_voice_over_rounded),
          ),
        ],
      ),
      extendBody: true,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: isShowBottom ? sizeBottom : 0),
              child: Column(
                children: [
                  ..._dataRecord
                      .map(
                        (item) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          dense: true,
                          onTap: () {
                            final isPlaying = _urlPlay == item.title;
                            if (isPlaying) {
                              return;
                            } else {
                              if (_offset == kOffsetHide) {
                                _offset = kOffsetShow;
                              }

                              _playAudio(item.url);
                            }
                          },
                          title: Text(
                            item.title ?? 'record',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: Text(item.totalTime.hhmmss),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
            if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
              Positioned(
                bottom: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: MediaQuery.of(context).viewInsets.bottom != 0
                      ? kOffsetHide
                      : _offset,
                  child: EasyAudioPlayer(
                    controller: _audioController,
                    formatTimeSlider: (duration) => duration.hhmmss,
                    builderSlider: (duration, posision, isLoadDone) {
                      var timeValue = 0.0;
                      if (isLoadDone && posision != null && duration != null) {
                        timeValue =
                            posision.inMilliseconds / duration.inMilliseconds;
                      }

                      return Slider(
                        activeColor: Theme.of(context).primaryColor,
                        inactiveColor: Theme.of(context).colorScheme.secondary,
                        value: timeValue,
                        onChanged: (value) {},
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: SafeArea(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: MediaQuery.of(context).viewInsets.bottom != 0
                        ? kOffsetHide
                        : (_offset == kOffsetHide ? kOffsetShow : kOffsetHide),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _onTapStartRecord,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
