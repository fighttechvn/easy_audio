import 'package:flutter/foundation.dart';

@immutable
abstract class RecordSessionData {
  String get sessionId;

  Map<String, dynamic> toJson();
}

@immutable
class SimpleRecordSessionData implements RecordSessionData {
  const SimpleRecordSessionData({
    required this.sessionId,
    this.metadata = const {},
  });

  @override
  final String sessionId;

  final Map<String, dynamic> metadata;

  @override
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        ...metadata,
      };

  SimpleRecordSessionData copyWith({
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return SimpleRecordSessionData(
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
    );
  }
}
