import 'package:flutter/material.dart';

import '../../core/widgets/group_check_box_widget.dart';

const languageEng = 'English';
const langueVn = 'Vietnamese';
const langueEs = 'Spanish';
const langueFr = 'French';
const langueCn = 'Chinese';
const langueArabic = 'Saudi Arabia';
const langueIndia = 'Hindi';

class RecordLanguageContants {
  static const String defaultLang = languageEng;

  static const languages = {
    languageEng: 'en-US',
    langueCn: 'zh-CN',
    langueFr: 'fr-FR',
    langueEs: 'es-ES',
    langueVn: 'vi_VN',
    langueArabic: 'ar-SA',
    langueIndia: 'hi-IN',
  };
}

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
  late var _languageSelected = widget.langDefault;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            size: 50,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '''Choose lanuage to use record.''',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 26),

          GroupCheckBoxWidget<String>(
            values: widget.languages.keys.toList(),
            defaultValue: _languageSelected,
            onSelected: (value) {
              setState(() {
                _languageSelected = value!;
              });
            },
            isRadioType: true,
            direction: Axis.vertical,
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
