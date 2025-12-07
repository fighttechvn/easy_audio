import 'package:flutter/material.dart';
import '../../../core/easy_debounce.dart';

class LanguageSearchBar extends StatelessWidget {
  const LanguageSearchBar({
    super.key,
    required this.onChanged,
    this.debounceTag = '_select_lang',
  });

  final ValueChanged<String> onChanged;
  final String debounceTag;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration:
          const InputDecoration(hint: Text('Search country or language')),
      onChanged: (value) {
        EasyDebounce.debounce(
          debounceTag,
          const Duration(milliseconds: 400),
          () => onChanged(value),
        );
      },
    );
  }
}
