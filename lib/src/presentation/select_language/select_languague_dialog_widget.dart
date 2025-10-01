import 'package:flutter/material.dart';

import '../../core/easy_debounce.dart';
import '../../core/widgets/group_check_box_widget.dart';
import '../../easy_audio_constants.dart';

class SelectLanguagueDialogWidget extends StatefulWidget {
  final String langDefault;
  final Map<String, String> languages;

  const SelectLanguagueDialogWidget({
    super.key,
    this.langDefault = RecordLanguageContants.defaultLang,
    this.languages = RecordLanguageContants.languages,
  });

  @override
  State<SelectLanguagueDialogWidget> createState() =>
      _SelectLanguagueDialogWidgetState();
}

class _SelectLanguagueDialogWidgetState
    extends State<SelectLanguagueDialogWidget> {
  late List<String> _currentList = widget.languages.keys.toList();

  late String _languageSelected = widget.langDefault;
  final _tagDebound = '_select_lang';

  @override
  void dispose() {
    EasyDebounce.cancel(_tagDebound);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            onChanged: (value) {
              EasyDebounce.debounce(
                _tagDebound,
                const Duration(milliseconds: 400),
                () {
                  if (value.isEmpty) {
                    _currentList = widget.languages.keys.toList();
                    setState(() {});
                  } else {
                    _currentList = widget.languages.keys
                        .where((e) => e.contains(value))
                        .toList();
                    setState(() {});
                  }
                },
              );
            },
          ),
          const SizedBox(height: 26),

          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: SingleChildScrollView(
              child: GroupCheckBoxWidget<String>(
                values: _currentList,
                defaultValue: _languageSelected,
                onSelected: (value) {
                  setState(() {
                    _languageSelected = value!;
                  });
                },
                isRadioType: true,
                direction: Axis.vertical,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final lang = widget.languages[_languageSelected];
              Navigator.of(context).pop(lang);
            },
            child: const Text('Confirm'),
          ),
          // const SizedBox(height: 6),
          // OutlinedButton(
          //   onPressed: Navigator.of(context).pop,
          //   child: const Text('Cancel'),
          // ),
        ],
      ),
    );
  }
}
