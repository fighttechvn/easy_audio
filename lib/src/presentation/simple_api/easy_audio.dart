// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../core/services/easy_audio_controller.dart';
import '../../core/services/record_modal_service.dart';
import '../../domain/entities/record_data.dart';
import 'easy_audio_config.dart';

/// Internal session data class for simplified API.
/// Users don't need to create their own session data class.
class _SimpleSessionData {
  const _SimpleSessionData();
}

class EasyAudio {
  EasyAudio._({
    required this.config,
    required this.navigatorKey,
  });

  static EasyAudio? _instance;

  /// Get singleton instance.
  ///
  /// Must call [initialize] first, otherwise throws assertion error.
  static EasyAudio get instance {
    assert(
      _instance != null,
      'EasyAudio not initialized! Call EasyAudio.initialize() first.',
    );
    return _instance!;
  }

  /// Check if EasyAudio has been initialized.
  static bool get isInitialized => _instance != null;

  /// Current configuration.
  final EasyAudioConfig config;

  /// Navigator key used for showing modals.
  final GlobalKey<NavigatorState> navigatorKey;

  static void initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    EasyAudioConfig config = const EasyAudioConfig(),
  }) {
    _instance = EasyAudio._(
      config: config,
      navigatorKey: navigatorKey,
    );
    RecordModalService.instance.initialize(navigatorKey);
    debugPrint('[EasyAudio] Initialized with locale: ${config.defaultLocale}');
  }

  /// Reset the instance (useful for testing).
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  void setUserId(String? userId) {
    RecordModalService.instance.setCurrentUserId(userId);
    debugPrint('[EasyAudio] Set user ID: $userId');
  }

  Future<RecordData?> openRecordModal({
    String? title,
    String? locale,
    Future<void> Function(RecordData result)? onComplete,
  }) async {
    final effectiveLocale = locale ?? config.defaultLocale;
    final effectiveTitle = title ?? config.defaultTranscriptLabel;

    Future<bool?> onExitCallback(BuildContext context) async {
      if (!config.confirmOnExit) {
        return true;
      }
      return _showConfirmExitDialog(context);
    }

    final result =
        await RecordModalService.instance.openModal<_SimpleSessionData>(
      locale: effectiveLocale,
      data: const _SimpleSessionData(),
      transcript: effectiveTitle,
      onExit: onExitCallback,
      restoreFromSession: false,
      isSameData: (_, __) => true,
      validData: (_) => true,
    );

    if (result != null) {
      // Call the appropriate callback
      final callback = onComplete ?? config.onRecordComplete;
      if (callback != null) {
        await callback(result);
      }
    }

    return result;
  }

  /// Show confirmation dialog when user tries to exit recording.
  Future<bool?> _showConfirmExitDialog(BuildContext context) {
    final loc = config.localizations;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.stopRecordingTitle),
        content: Text(loc.stopRecordingMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.stopButton),
          ),
        ],
      ),
    );
  }

  EasyAudioController createPlayerController() {
    return EasyAudioController.withBackgroundMode();
  }

  BuildContext? get context => navigatorKey.currentContext;
}
