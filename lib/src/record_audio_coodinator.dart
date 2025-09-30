import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/dialog_coodinator.dart';
import 'domain/entities/record_data.dart';
import 'domain/usecase/speech_to_text_usecase.dart';
import 'easy_audio_constants.dart';
import 'presentation/record_modal/bloc/speech_text_bloc.dart';
import 'presentation/record_modal/record_modal_widget.dart';
import 'presentation/select_language/select_languague_dialog_widget.dart';

extension BuildContextAnimatedWaveform on BuildContext {
  Future<RecordData?> startRecord({
    Future<bool?> Function()? onExits,
    String? transcript,
    String locale = 'en-US',
  }) {
    return showModalBottomSheet<RecordData?>(
      context: this,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.black26,
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
          ),
        );
      },
    );
  }

  Future<String?> startSelectLanguagueDialog({
    String langDefault = RecordLanguageContants.defaultLang,
    Map<String, String> languages = RecordLanguageContants.languages,
  }) {
    return startDialogApp(
      title: 'Select lanuage to use',
      body: SelectLanguagueDialogWidget(
        langDefault: langDefault,
        languages: languages,
      ),
      showButtonClose: false,
      barrierDismissible: true,
    );
  }
}
