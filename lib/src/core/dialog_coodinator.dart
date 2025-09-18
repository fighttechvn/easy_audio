import 'package:flutter/material.dart';

import 'widgets/dialog_container_widget.dart';

extension DialogCoodinator on BuildContext {
  Future<T?> startDialogApp<T>({
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
}
