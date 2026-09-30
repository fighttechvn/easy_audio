import 'package:just_audio_background/just_audio_background.dart';

/// Installs the background-playback platform shim used by
/// [AudioPlaybackManager].
///
/// Must be awaited from `main()` before any `AudioPlayer` is constructed:
/// `just_audio_background` works by swapping out the `just_audio` platform
/// implementation, and players created earlier keep the plain one.
class EasyAudioBackground {
  EasyAudioBackground._();

  static bool _initialized = false;

  /// Safe to call more than once; only the first call takes effect.
  static Future<void> init({
    String androidNotificationChannelId = 'vn.fighttech.easy_audio.playback',
    String androidNotificationChannelName = 'Audio playback',
    String? androidNotificationChannelDescription,
    String androidNotificationIcon = 'mipmap/ic_launcher',
  }) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await JustAudioBackground.init(
      androidNotificationChannelId: androidNotificationChannelId,
      androidNotificationChannelName: androidNotificationChannelName,
      androidNotificationChannelDescription:
          androidNotificationChannelDescription,
      androidNotificationIcon: androidNotificationIcon,
      // Keeps the service in the foreground while playing so Android will not
      // reclaim the process; pairing it with stopForegroundOnPause is required,
      // otherwise the notification becomes undismissable after pausing.
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      // Match the +/- 5s buttons the in-app player exposes.
      fastForwardInterval: const Duration(seconds: 5),
      rewindInterval: const Duration(seconds: 5),
    );
  }
}
