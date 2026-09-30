import '../entities/easy_audio_mode.dart';
import '../entities/easy_audio_service_context.dart';
import '../entities/supported_locale.dart';

class EasyAudioPermissionsUseCase {
  Future<bool> hasRecordPermission(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();
    return ctx.sttRecord!.hasPermission();
  }

  Future<bool> hasSpeechPermission(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();
    if (ctx.config.mode == EasyAudioMode.recordOnly) {
      return true;
    }
    return ctx.sttRecord!.hasPermission();
  }

  Future<bool> requestPermissions(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final ok = await ctx.sttRecord!.requestPermission();
    ctx.speechAvailable = ok;
    return ok;
  }

  Future<List<SupportedLocale>> getSupportedLocales(
    EasyAudioServiceContext ctx,
  ) async {
    ctx.ensureInitialized();

    final locales = await ctx.sttRecord!.getLocales();
    final result = locales
        .map((l) => SupportedLocale(localeId: l.localeId, name: l.name))
        .toList();

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
