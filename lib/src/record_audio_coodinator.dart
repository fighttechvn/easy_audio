import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'domain/entities/record_data.dart';
import 'domain/usecase/speech_to_text_usecase.dart';
import 'presentation/record_modal/bloc/speech_text_bloc.dart';
import 'presentation/record_modal/record_modal_widget.dart';

extension BuildContextAnimatedWaveform on BuildContext {
  Future<RecordData?> startRecord({
    Future<bool?> Function()? onExits,
    String? transcript,
    String locale = 'en-US',
    Color? backgroundColor,
    Color? colorWaveformView,
  }) {
    Color bgColorDefault = const Color(0xff18203A);
    Color? colorWaveformViewDefault;

    if (Theme.brightnessOf(this) == Brightness.light) {
      bgColorDefault = Colors.white;
      colorWaveformViewDefault = const Color(0xff8F9BB3);
    }

    return showModalBottomSheet<RecordData?>(
      context: this,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: backgroundColor ?? bgColorDefault,
      barrierColor: Colors.black12,
      builder: (BuildContext context) {
        return BlocProvider<SpeechTextBloc>(
          create: (context) =>
              SpeechTextBloc(SpeechToTextUsecase(local: locale)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(this).size.height * 0.9),
            child: RecordModalWidget(
              onExits: onExits,
              title: transcript,
              locale: locale,
              colorWaveformView: colorWaveformView ?? colorWaveformViewDefault,
            ),
          ),
        );
      },
    );
  }

  // Future<String?> startSelectLanguagueDialog({
  //   String langDefault = RecordLanguage.defaultLocale,
  //   Map<String, String>? languages,
  //   String? title,
  // }) {
  //   return startDialogApp(
  //     title: title ?? 'Select lanuage to use',
  //     body: SelectLanguagueDialogWidget(
  //       langDefault: langDefault,
  //       languages: languages,
  //     ),
  //     showButtonClose: false,
  //     barrierDismissible: true,
  //   );
  // }
}
