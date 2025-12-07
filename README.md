# Easy Audio

Flutter plugin for audio recording with speech-to-text support.

## Features

- Audio recording with background mode support
- Speech-to-text transcription (using Vosk + native STT)
- Audio playback with controls
- Session management (minimize/restore/resume)
- Floating widget for recording control
- Multi-language support (40+ languages)
- Crash recovery for pending recordings

---

## Quick Start (Simple API)

For simple use cases, use the **Simple API** - minimal setup, maximum productivity.

### 1. Initialize in main.dart

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final navigatorKey = GlobalKey<NavigatorState>();
  
  EasyAudio.initialize(
    navigatorKey: navigatorKey,
    config: EasyAudioConfig(
      defaultLocale: 'en-US',
      confirmOnExit: true,
      localizations: EasyAudioLocalizations(), // or EasyAudioLocalizations.vi
    ),
  );
  
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    home: MyHomePage(),
  ));
}
```

### 2. Open Recording Modal

```dart
// Simple - just open and get result
final result = await EasyAudio.instance.openRecordModal(
  title: 'My Recording',
);

if (result != null) {
  print('Audio saved to: ${result.url}');
  print('Transcript: ${result.content}');
  print('Duration: ${result.totalTime}ms');
}
```

### 3. Play Audio

```dart
// Self-contained player - just pass a URL!
SimpleAudioPlayer(
  url: recordingUrl,
  title: 'My Recording',
  expanded: true,
),
```

### 4. Using SimpleRecordMixin (Optional)

For screens with recording functionality:

```dart
class MyRecordingPage extends StatefulWidget {
  @override
  State<MyRecordingPage> createState() => _MyRecordingPageState();
}

class _MyRecordingPageState extends State<MyRecordingPage>
    with SimpleRecordMixin {
  
  @override
  Future<void> onRecordComplete(RecordData result) async {
    // Handle completed recording (upload, save, etc.)
    await uploadFile(result.url);
  }

  @override
  Future<bool> requestPermissions() async {
    // Use your preferred permission handler
    return await Permission.microphone.request().isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: startRecording, // Provided by mixin
      child: Text('Record'),
    );
  }
}
```

---

## Advanced Usage

For complex scenarios (custom session management, BLoC integration, etc.),
use the advanced API with `RecordBloc`, `BaseRecordSessionMixin`, etc.

See [Advanced Documentation](./docs/doc-easy-audio.md) for details.

---

## Dependencies 

- [audioplayers](https://pub.dev/packages/audioplayers)
- [record](https://pub.dev/packages/record)
- [speech_to_text_record](./plugins/speech_to_text_record) (bundled)
- [vosk_flutter](./plugins/speech_to_text_record/packages/vosk_flutter) (bundled)

---

## Platform Setup

Please make sure to handle permissions. (Recommend: [permission_handler](https://pub.dev/packages/permission_handler))


# How to Setup
## Android

### Update `android/app/build.gradle`
```bash
compileSdkVersion 34 (33 or lower if you use gradle 7.x)

```

Add file key.properties 
```bash
storePassword=123456
keyPassword=123456
keyAlias=keystore
storeFile=<path into upload keystore file>

```



minSdkVersion 21


File update `android/app/src/main/AndroidManifest.xml`

```bash
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## iOS

### Update `ios/Runner/Info.plist`

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Allow $(APP_NAME) access microphone?</string>

<!-- For background recording (optional) -->
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### Background Recording Support (iOS)

To enable background recording on iOS, you can configure `EasyAudioController` with the following options:

```dart
import 'package:easy_audio/easy_audio.dart';

// Basic usage (default behavior - pauses on interruption)
final controller = EasyAudioController();

// For background recording with automatic pause/resume
final controller = EasyAudioController(
  audioInterruption: AudioInterruptionMode.pauseResume,
  iosConfig: IosRecordConfig(
    categoryOptions: [
      IosAudioCategoryOption.mixWithOthers,  // Required for pauseResume mode
      IosAudioCategoryOption.defaultToSpeaker,
      IosAudioCategoryOption.allowBluetooth,
      IosAudioCategoryOption.allowBluetoothA2DP,
    ],
  ),
);

// For background recording without interruption handling
final controller = EasyAudioController(
  audioInterruption: AudioInterruptionMode.none,
);
```

**AudioInterruptionMode options:**
- `none`: Recording continues regardless of interruptions (e.g., phone calls)
- `pause`: Automatically pauses on interruption, manual resume required
- `pauseResume`: Automatically pauses and resumes on interruption (requires `mixWithOthers`)

**Note:** Make sure `UIBackgroundModes` with `audio` is added to your `Info.plist` for background recording to work.

## Locales supported

```bash
flutter: locales 63
 Arabic (Saudi Arabia) ar-SA
 Cantonese (China mainland) yue-CN
 Catalan (Spain) ca-ES
 Chinese (China mainland) zh-CN
 Chinese (Hong Kong) zh-HK
 Chinese (Taiwan) zh-TW
 Croatian (Croatia) hr-HR
 Czech (Czechia) cs-CZ
 Danish (Denmark) da-DK
 Dutch (Belgium) nl-BE
 Dutch (Netherlands) nl-NL
 English (Australia) en-AU
 English (Canada) en-CA
 English (India) en-IN
 English (Indonesia) en-ID
 English (Ireland) en-IE
 English (New Zealand) en-NZ
 English (Philippines) en-PH
 English (Saudi Arabia) en-SA
 English (Singapore) en-SG
 English (South Africa) en-ZA
 English (United Arab Emirates) en-AE
 English (United Kingdom) en-GB
 English (United States) en-US
 English (Vietnam) en-VN
 Finnish (Finland) fi-FI
 French (Belgium) fr-BE
 French (Canada) fr-CA
 French (France) fr-FR
 French (Switzerland) fr-CH
 German (Austria) de-AT
 German (Germany) de-DE
 German (Switzerland) de-CH
 Greek (Greece) el-GR
 Hebrew (Israel) he-IL
 Hindi (India) hi-IN
 Hindi (Latin) hi-Latn
 Hungarian (Hungary) hu-HU
 Indonesian (Indonesia) id-ID
 Italian (Italy) it-IT
 Italian (Switzerland) it-CH
 Japanese (Japan) ja-JP
 Korean (South Korea) ko-KR
 Malay (Malaysia) ms-MY
 Norwegian Bokmål (Norway) nb-NO
 Polish (Poland) pl-PL
 Portuguese (Brazil) pt-BR
 Portuguese (Portugal) pt-PT
 Romanian (Romania) ro-RO
 Russian (Russia) ru-RU
 Shanghainese (China mainland) wuu-CN
 Slovak (Slovakia) sk-SK
 Spanish (Chile) es-CL
 Spanish (Colombia) es-CO
 Spanish (Latin America) es-419
 Spanish (Mexico) es-MX
 Spanish (Spain) es-ES
 Spanish (United States) es-US
 Swedish (Sweden) sv-SE
 Thai (Thailand) th-TH
 Turkish (Türkiye) tr-TR
 Ukrainian (Ukraine) uk-UA
 Vietnamese (Vietnam) vi-VN
```

