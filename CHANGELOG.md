## 3.1.0
+ Background playback with lock screen / Control Center controls, via `just_audio_background`.
+ `AudioPlaybackManager` now attaches a `MediaItem` tag to every source and asserts the
  `music()` audio session before playing. Recording leaves the shared iOS session in a
  record category, so this has to happen on every play, not once at startup.
+ New `AudioMetadata` (title / album / artist / artUri) accepted by `playUrl`,
  `playSource`, `toggleUrl` and `toggleSource`. It drives the now-playing entry.
+ New `EasyAudioBackground.init()`; host apps must await it in `main()` before the first
  `AudioPlayer` is created.
+ Recovery no longer spins up a throwaway `AudioPlayer` to probe durations — it reads the
  WAV header instead. `just_audio_background` routes all players through one global
  handler, so a second player would have stopped whatever was playing.

### Host app changes required
+ Android: `MainActivity` must extend `AudioServiceActivity` (or
  `AudioServiceFragmentActivity`), and the manifest must declare
  `com.ryanheise.audioservice.AudioService`, `MediaButtonReceiver`, plus the
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `WAKE_LOCK` permissions.
+ iOS: `UIBackgroundModes` must include `audio`.

## 1.0.2
+ Support resume audio

## 1.0.1
+ Add wake screen while recoding

## 0.0.12
* Upgrade `flutter_bloc: ^9.1.0`

## 0.0.11
+ Show locale in buttomsheet transcript

## 0.0.8
+ EasyAudioController supports seek audio 

## 0.0.8
+ Update dependency `audioplayers: 5.0.0`

## 0.0.7
+ Default speed to text is `en-US`

## 0.0.6
- Handle exit record modal

## 0.0.4

- Fix bug when initializing service for the first time

## 0.0.1

+ Add record audio
+ Support `speech_to_text`
