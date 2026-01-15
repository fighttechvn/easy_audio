# Easy Audio Demo (example)

This is the demo app for the `easy_audio` package.

## Demo features

- Record audio to a file (via `easy_audio`)
- Streaming transcript (speech-to-text)
- “Recent Recordings” list
- Play/Pause/Seek recorded files (via `just_audio`)
- “Detail mode” UI:
  - Select an audio item → shows playback controls
  - Select a transcript-only item → shows transcript card
  - Close button to exit detail mode

## Run the project

```bash
cd example
flutter pub get
flutter run
```

## Platform setup

### Android (background recording)

The demo already declares the required permissions + service in `android/app/src/main/AndroidManifest.xml` to enable background recording via a foreground service.

Note: On Android 13+ you may need to request runtime permission `POST_NOTIFICATIONS` so the foreground-service notification is shown correctly.

### iOS

`ios/Runner/Info.plist` already includes:

- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `UIBackgroundModes` (audio)
