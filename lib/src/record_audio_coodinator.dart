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
    return showModalBottomSheet<RecordData?>(
      context: this,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: backgroundColor ?? const Color(0xff18203A) ,
      barrierColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(this).size.height),
      builder: (BuildContext context) {
        return BlocProvider<SpeechTextBloc>(
          create: (context) =>
              SpeechTextBloc(SpeechToTextUsecase(local: locale)),
          child: RecordModalWidget(
            onExits: onExits,
            title: transcript,
            locale: locale,
            colorWaveformView: colorWaveformView,
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
