import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

const kOffsetHide = Offset(0, 2);
const kOffsetShow = Offset(0, 0);

final kMockDataRecord = [
  RecordData(
    title: 'Recording',
    createdAt: DateTime(2022, 12, 5, 09, 25),
    id: '006',
    totalTime: const Duration(seconds: 91),
    url:
        'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
  ),
];

extension DurationExt on Duration {
  String get hhmmss {
    return toString().split('.').first.padLeft(8, '0');
  }
}
