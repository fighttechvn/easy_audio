import 'package:flutter/foundation.dart';

@immutable
class SupportedLocale {
  const SupportedLocale({required this.localeId, required this.name});

  final String localeId;

  final String name;
}
