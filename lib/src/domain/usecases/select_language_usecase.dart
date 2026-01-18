import 'package:shared_preferences/shared_preferences.dart';

import '../../features/shared/services/easy_audio/easy_audio_service.dart';
import '../entities/select_language_data.dart';
import '../entities/supported_locale.dart';

const String _recentLocalesKey = 'app_main.record_language_recent_locales.v1';
const int _maxRecent = 10;

class SelectLanguageUseCase {
  Future<SharedPreferences> get _prefsInstance =>
      SharedPreferences.getInstance();

  Future<SelectLanguageData> loadLocales({
    required EasyAudioService easyAudio,
  }) async {
    final locales = await easyAudio.getSupportedLocales();
    final prefs = await _prefsInstance;
    final recentIds =
        prefs.getStringList(_recentLocalesKey) ?? const <String>[];

    final byId = <String, SupportedLocale>{
      for (final l in locales) l.localeId: l,
    };

    final recentLocales = <SupportedLocale>[];
    for (final id in recentIds) {
      final found = byId[id];
      if (found != null) {
        recentLocales.add(found);
      }
    }

    String? selectedId;
    if (recentLocales.isNotEmpty) {
      selectedId = recentLocales.first.localeId;
    } else if (locales.isNotEmpty) {
      var index = locales.indexWhere(
        (l) => l.localeId == 'en_US' || l.localeId == 'en-US',
      );

      if (index == -1) {
        index = locales.indexWhere(
          (l) => l.localeId.startsWith('en'),
        );

        if (index == -1) {
          index = 0;
        }
      }

      final itemSelected = locales[index];
      selectedId = itemSelected.localeId;
      locales.removeAt(index);
      locales.insert(0, itemSelected);
    }

    return SelectLanguageData(
      allLocales: locales,
      recentLocales: recentLocales,
      selectedLocaleId: selectedId,
    );
  }

  Future<void> persistRecentLocale({required String localeId}) async {
    final prefs = await _prefsInstance;
    final existing = prefs.getStringList(_recentLocalesKey) ?? <String>[];
    final updated = <String>[
      localeId,
      ...existing.where((e) => e.trim().isNotEmpty && e != localeId),
    ].take(_maxRecent).toList(growable: false);
    await prefs.setStringList(_recentLocalesKey, updated);
  }
}
