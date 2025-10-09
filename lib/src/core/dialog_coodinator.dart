import 'package:flutter/material.dart';

import '../../easy_audio.dart';
import 'widgets/dialog_container_widget.dart';

extension EasyAudioDialogCoodinator on BuildContext {
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
}
