import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

import 'core/services/language_history_service.dart';
import 'core/services/pending_recording_service.dart';
import 'core/widgets/dialog_container_widget.dart';
import 'domain/entities/record_data.dart';
import 'domain/usecase/speech_to_text_usecase.dart';
import 'presentation/pending_recovery/widgets/pending_recording_dialog.dart';
import 'presentation/record_modal/bloc/speech_text_bloc.dart';
import 'presentation/record_modal/record_modal_widget.dart';
import 'presentation/select_language/select_languague_dialog_widget.dart';
import 'presentation/shared/app_dialog.dart';

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

    return showAppBottomSheet<RecordData?>(
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

  Future<T?> startDialogContainer<T>({
    String? title,
    Widget? titleWidget,
    Widget? body,
    bool showButtonClose = true,
    bool barrierDismissible = true,
    bool showTitle = true,
  }) async {
    return showGeneralDialog(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      pageBuilder: (_, __, ___) => Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DialogContainerWidget(
              title: title,
              showButtonClose: showButtonClose,
              showTitle: showTitle,
              child: body,
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> startSelectLanguague({
    String langDefault = RecordLanguage.defaultLocale,
    Map<String, String>? languages,
    String title = 'Select lanuage to use',
  }) async {
    // Prefer previously selected language if available,
    // otherwise use current default
    final recentlyUsed =
        await LanguageHistoryService.getRecentlyUsedLanguages();
    final preferredLabel = recentlyUsed.firstWhere(
      (label) => RecordLanguage.supported.containsKey(label),
      orElse: () => langDefault,
    );

    final selectedLocale = await startDialogContainer(
      title: title,
      body: SelectLanguagueDialogWidget(
        langDefault: preferredLabel,
        languages: RecordLanguage.supported,
      ),
      showButtonClose: false,
      barrierDismissible: true,
    );

    return selectedLocale;
  }

  /// Dialog hiển thị pending recording cần recovery.
  Future<PendingRecordingResult?> showPendingRecordingDialog({
    required PendingRecording recording,
    PendingRecordingDialogConfig config = const PendingRecordingDialogConfig(),
  }) {
    return showDialog<PendingRecordingResult>(
      context: this,
      barrierDismissible: config.barrierDismissible,
      builder: (ctx) => PendingRecordingDialog(
        recording: recording,
        config: config,
      ),
    );
  }
}
