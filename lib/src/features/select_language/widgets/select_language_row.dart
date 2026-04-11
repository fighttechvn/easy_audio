import 'package:flutter/material.dart';

import '../../../domain/entities/supported_locale.dart';
import 'select_language_radio_dot.dart';

class SelectLanguageRow extends StatelessWidget {
  const SelectLanguageRow({
    super.key,
    required this.locale,
    required this.selected,
    required this.loading,
    required this.accentColor,
    required this.onSelected,
  });

  final SupportedLocale locale;
  final bool selected;
  final bool loading;
  final Color accentColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : () => onSelected(locale.localeId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            SelectLanguageRadioDot(
              selected: selected,
              accentColor: accentColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale.name,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
