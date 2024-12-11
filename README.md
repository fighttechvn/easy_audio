# Easy Audio
+ Support record audio file.
+ Friendly support convert speed to text.

# How to use
```
context.startRecord()
```


Please make sure have handle permission. (Can use: `https://pub.dev/packages/permission_handler`)

# How to Setup
## Android

### Update `android/app/build.gradle`
```
compileSdkVersion 34 (33 or lower if you use gradle 7.x)

```

### key.properties 
storePassword=123456
keyPassword=123456
keyAlias=keystore
storeFile=<path into upload keystore file>

```

minSdkVersion 21

```

### Update `android/app/src/main/AndroidManifest.xml`

```
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## iOS

### Update `ios/Runner/Info.plist`

```
	<key>NSMicrophoneUsageDescription</key>
	<string>Allow $(APP_NAME) access microphone?</string>
```