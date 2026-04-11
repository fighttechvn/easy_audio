import 'package:flutter/material.dart';

class SelectLanguageRadioDot extends StatelessWidget {
  const SelectLanguageRadioDot({
    super.key,
    required this.selected,
    required this.accentColor,
    this.unselectedBorderColor = const Color(0xFFBDBDBD),
    this.size = 18,
    this.borderWidth = 2,
  });

  final bool selected;
  final Color accentColor;
  final Color unselectedBorderColor;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accentColor : Colors.transparent,
        border: selected
            ? null
            : Border.all(
                color: unselectedBorderColor,
                width: borderWidth,
              ),
      ),
    );
  }
}
