package com.example.example

import com.ryanheise.audioservice.AudioServiceActivity

// Required by EasyAudioBackground: audio_service owns the FlutterEngine so the
// media notification outlives this activity.
class MainActivity : AudioServiceActivity()
