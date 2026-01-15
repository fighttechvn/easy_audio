import 'package:record/record.dart';

import '../../domain/entities/easy_audio_config.dart';
import '../../domain/entities/easy_audio_mode.dart';

class RecordConfigFactory {
  RecordConfigFactory._();

  static RecordConfig build(EasyAudioConfig config) {
    if (config.mode == EasyAudioMode.speechToTextOnly) {
      throw StateError('RecordConfigFactory.build called in speechToTextOnly');
    }

    return RecordConfig(
      encoder: config.encoder,
      sampleRate: config.sampleRate,
      bitRate: config.bitRate,
      numChannels: config.numChannels,
      iosConfig: const IosRecordConfig(
        categoryOptions: [
          IosAudioCategoryOption.mixWithOthers,
          IosAudioCategoryOption.defaultToSpeaker,
          IosAudioCategoryOption.allowBluetooth,
          IosAudioCategoryOption.allowBluetoothA2DP,
        ],
      ),
      androidConfig: AndroidRecordConfig(
        service: config.enableBackgroundRecording
            ? (config.androidService ??
                  const AndroidService(
                    title: 'Recording in progress',
                    content: 'Tap to return to the app',
                  ))
            : null,
      ),
    );
  }
}
