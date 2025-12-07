import 'package:flutter/material.dart';
import '../../../core/widgets/group_check_box_widget.dart';

class LanguageListView extends StatelessWidget {
  const LanguageListView({
    super.key,
    required this.currentList,
    required this.languageSelected,
    required this.onSelected,
  });

  final List<String> currentList;
  final String languageSelected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: SingleChildScrollView(
        child: GroupCheckBoxWidget<String>(
          values: currentList,
          defaultValue: languageSelected,
          onSelected: onSelected,
          isRadioType: true,
          direction: Axis.vertical,
        ),
      ),
    );
  }
}
