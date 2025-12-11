# Unified Mic Pipeline Demo

This example app showcases how the `speech_to_text_record` package coordinates
microphone access for two different goals:

- **Real-time speech-to-text** powered by `vosk_flutter` on Android and the
  `speech_to_text` plugin on iOS.
- **File recording** to a PCM WAV file using the `record` package.

The app exposes a single controller (`SpeechToTextRecordController`) that hides
platform differences while keeping the microphone locked to a single owner.

## Features

- Broadcast microphone stream on Android so transcription and recording can run
together.
- Automatic fallback to the `speech_to_text` plugin on iOS where the operating
system prevents multiple consumers from sharing the microphone.
- On-demand file recording with generated file names stored in the app
Documents directory.
- Optional playback of the last recording via `just_audio`.

## Platform Notes

| Platform | Speech engine | Recording behaviour |
| --- | --- | --- |
| Android / Linux / Windows | `VoskSpeechToTextEngine` (offline Vosk model) | Recording and STT can run together. |
| iOS / macOS | `SpeechToTextPluginEngine` (based on `speech_to_text`) | Microphone is exclusive to the speech engine. The app disables recording while STT is active. |

## Running the example

```bash
# From the repo root
flutter pub get
cd example
flutter pub get

# Android
flutter run -d <android_device>

# iOS
cd ios
pod install
cd ..
flutter run -d <ios_device>
```

When testing on iOS, start transcription first and speak a short sentence. Once
the pipeline stops, tap **Start recording** to capture a file and **Play last recording** to ensure audio was saved.
