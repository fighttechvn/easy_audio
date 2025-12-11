import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/logs/debug_print/record_modal_service_log.dart';
import '../../domain/entities/download_outcome.dart';
import '../../domain/entities/record_data.dart';
import '../record_modal/bloc/speech_text_bloc.dart';
import '../record_modal/record_modal_widget.dart';
import '../record_modal/record_session_manager.dart';
import '../select_language/widgets/download_progress_dialog.dart';

extension AppDialog on BuildContext {
  /// Shows a confirmation dialog with two actions (cancel/confirm).
  /// Returns `true` if confirmed, `false` otherwise.
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows an alert dialog with a single close button.
  Future<void> _showAlertDialog({
    required String title,
    required String message,
    String closeText = 'Close',
  }) {
    return showDialog<void>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(closeText),
          ),
        ],
      ),
    );
  }

  /// Dialog xác nhận dừng recording.
  /// Returns `true` nếu user muốn dừng, `null` nếu cancel.
  Future<bool?> showStopRecordingDialog({
    required String title,
    required String message,
    required String cancelText,
    required String stopText,
  }) async {
    final result = await _showConfirmDialog(
      title: title,
      message: message,
      cancelText: cancelText,
      confirmText: stopText,
    );
    return result ? true : null;
  }

  /// Dialog cảnh báo có recording đang active.
  /// Returns `true` nếu user muốn mở lại session, `false` nếu cancel.
  Future<bool> showRecordingInProgressDialog() async {
    final result = await showDialog<bool>(
      context: this,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Recording in Progress'),
        content: const Text(
          'There is currently an active recording session. '
          'You need to end the current recording session '
          'before starting a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reopen Recording Session'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> showDownloadConfirm(String label) async {
    return _showConfirmDialog(
      title: 'Download Language Model',
      message:
          'The model for "$label" is not available on this device.\nDo you '
          'want to download it now?',
      cancelText: 'No',
      confirmText: 'Download',
    );
  }

  Future<bool> showDownloadSuccess(String label) async {
    return _showConfirmDialog(
      title: 'Download successful',
      message: 'The model for "$label" is ready. Use it now?',
      cancelText: 'Later',
      confirmText: 'Confirm',
    );
  }

  Future<void> showDownloadError(String? message) {
    final displayMessage = message?.isNotEmpty == true
        ? message!
        : 'Unable to load model. Please try again later.';
    return _showAlertDialog(
      title: 'Model loading error',
      message: displayMessage,
      closeText: 'Close',
    );
  }

  Future showDownloadProgessDialog({
    required String label,
    required ValueListenable<double?> progressListenable,
    void Function(BuildContext context)? updateContext,
    required void Function() onCancel,
  }) {
    return showDialog<DownloadOutcome>(
      context: this,
      barrierDismissible: false,
      builder: (ctx) {
        updateContext?.call(ctx);
        return DownloadProgressDialog(
          languageLabel: label,
          progressListenable: progressListenable,
          onCancel: onCancel,
        );
      },
    );
  }

  /// Dialog xác nhận tải model ngôn ngữ.
  Future<bool> showDownloadModelConfirmDialog(String languageLabel) {
    return _showConfirmDialog(
      title: 'Download Language Model',
      message:
          'The model for "$languageLabel" is not available on this device.\n'
          'Do you want to download it now?',
      cancelText: 'No',
      confirmText: 'Download',
    );
  }

  /// Dialog thông báo tải model thành công.
  Future<bool> showDownloadSuccessDialog(String languageLabel) {
    return _showConfirmDialog(
      title: 'Download successful',
      message: 'The model for "$languageLabel" is ready. Use it now?',
      cancelText: 'Later',
      confirmText: 'Confirm',
    );
  }

  /// Dialog thông báo lỗi tải model.
  Future<void> showDownloadErrorDialog(String? errorMessage) {
    final displayMessage = errorMessage?.isNotEmpty == true
        ? errorMessage!
        : 'Unable to load model. Please try again later.';
    return _showAlertDialog(
      title: 'Model loading error',
      message: displayMessage,
      closeText: 'Close',
    );
  }

  Future<RecordData?> showRecordModal({
    required SpeechTextBloc bloc,
    required double maxHeight,
    Future<bool?> Function(BuildContext)? onExit,
    String? transcript,
    required String locale,
    required bool restoreFromSession,
    required RecordSessionManager sessionManager,
    void Function(bool shouldClose)? onUpdateUserExplicitlyClosed,
  }) async {
    return showAppBottomSheet<RecordData?>(
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: BoxConstraints(maxHeight: maxHeight),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.25,
          maxChildSize: 0.7,
          snap: true,
          snapSizes: const [0.3, 0.5, 0.7],
          builder: (ct, controller) {
            return BlocProvider<SpeechTextBloc>.value(
              value: bloc,
              child: RecordModalWidget(
                onExits: () async {
                  debugPrintUserClickedCloseButton();
                  if (mounted) {
                    final shouldClose =
                        await onExit?.call(mounted ? this : ct) ?? true;
                    if (shouldClose) {
                      onUpdateUserExplicitlyClosed?.call(true);
                      debugPrintUserConfirmedClose();
                    } else {
                      debugPrintUserCancelledClose();
                    }
                    return shouldClose;
                  }
                  return true;
                },
                title: transcript,
                locale: locale,
                restoreFromSession: restoreFromSession,
                onShouldMinimize: () {
                  debugPrintMinimizeButtonClicked();
                  sessionManager.minimizeSession();
                  Navigator.of(sheetContext).pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a modal bottom sheet with common configurations.
  Future<T?> showAppBottomSheet<T>({
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool isScrollControlled = false,
    bool enableDrag = true,
    Color? backgroundColor,
    Color? barrierColor,
    BoxConstraints? constraints,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      constraints: constraints,
      builder: builder,
    );
  }
}
