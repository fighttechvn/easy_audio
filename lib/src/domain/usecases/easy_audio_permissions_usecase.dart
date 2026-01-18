import 'package:speech_to_text/speech_to_text.dart';

import '../../core/utils/speech_to_text_utils.dart';
import '../entities/easy_audio_mode.dart';
import '../entities/easy_audio_service_context.dart';
import '../entities/supported_locale.dart';

class EasyAudioPermissionsUseCase {
  Future<bool> hasRecordPermission(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();
    return ctx.recorder!.hasPermission();
  }

  Future<bool> hasSpeechPermission(EasyAudioServiceContext ctx) async {
    if (ctx.speechToText == null) {
      return true;
    }
    return ctx.speechAvailable;
  }

  Future<bool> requestPermissions(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final bool hasRecord = await ctx.recorder!.hasPermission();
    if (!hasRecord) {
      return false;
    }

    if (ctx.config.mode != EasyAudioMode.recordOnly) {
      if (!ctx.speechAvailable) {
        return ctx.speechAvailable = await SpeechToTextUtils.ensureInitialized(
          ctx.speechToText!,
        );
      }
    }

    return true;
  }

  Future<List<SupportedLocale>> getSupportedLocales(
    EasyAudioServiceContext ctx,
  ) async {
    ctx.ensureInitialized();

    ctx.speechToText ??= SpeechToText();
    if (!ctx.speechAvailable) {
      ctx.speechAvailable = await SpeechToTextUtils.ensureInitialized(
        ctx.speechToText!,
      );
    }

    if (!ctx.speechAvailable) {
      return const [];
    }

    final locales = await ctx.speechToText!.locales();
    final result = locales
        .map((l) => SupportedLocale(localeId: l.localeId, name: l.name))
        .toList();

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
