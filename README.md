# Easy Audio
+ Support record audio file.
+ Friendly support convert speed to text.

# Dependencies 

	- [x] https://pub.dev/packages/audioplayers
	- [x] https://pub.dev/packages/record
	- [x] https://pub.dev/packages/speech_to_text
	- [] https://pub.dev/packages/flutter_tts

# How to use

```bash
context.startRecord()
```

Please make sure have handle permission. (Can use: `https://pub.dev/packages/permission_handler`)


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

