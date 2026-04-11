import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/language_selection.dart';
import '../../../domain/entities/supported_locale.dart';
import '../../../domain/usecases/select_language_usecase.dart';
import '../../../integration/audio/easy_audio/easy_audio_service.dart';
import 'select_language_state.dart';

class SelectLanguageCubit extends Cubit<SelectLanguageState> {
  SelectLanguageCubit({
    required SelectLanguageUseCase useCase,
    required EasyAudioService easyAudio,
  })  : _useCase = useCase,
        _easyAudio = easyAudio,
        super(SelectLanguageState.initial());

  final SelectLanguageUseCase _useCase;
  final EasyAudioService _easyAudio;

  Future<void> loadLocales() async {
    emit(state.copyWith(loading: true));

    try {
      final data = await _useCase.loadLocales(easyAudio: _easyAudio);

      final next = state.copyWith(
        loading: false,
        allLocales: data.allLocales,
        recentLocales: data.recentLocales,
        selectedLocaleId: data.selectedLocaleId,
      );

      emit(_applyFilter(next));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          allLocales: const <SupportedLocale>[],
          recentLocales: const <SupportedLocale>[],
          filteredRecent: const <SupportedLocale>[],
          filteredAll: const <SupportedLocale>[],
          selectedLocaleId: null,
        ),
      );
    }
  }

  void applyFilter(String query) {
    emit(_applyFilter(state.copyWith(query: query)));
  }

  void selectLocale(String localeId) {
    emit(state.copyWith(selectedLocaleId: localeId));
  }

  Future<LanguageSelection> confirm() async {
    final selected = state.selectedLocaleId?.trim();
    if (selected == null || selected.isEmpty) {
      return const LanguageSelection(localeId: null);
    }

    await _useCase.persistRecentLocale(localeId: selected);
    return LanguageSelection(localeId: selected);
  }

  SelectLanguageState _applyFilter(SelectLanguageState current) {
    final q = current.query.trim().toLowerCase();

    bool matches(SupportedLocale l) {
      if (q.isEmpty) {
        return true;
      }
      return l.name.toLowerCase().contains(q) ||
          l.localeId.toLowerCase().contains(q);
    }

    final recentMatched =
        current.recentLocales.where(matches).toList(growable: false);
    final recentIdSet = recentMatched.map((e) => e.localeId).toSet();
    final othersMatched = current.allLocales
        .where((e) => !recentIdSet.contains(e.localeId))
        .where(matches)
        .toList(growable: false);

    return current.copyWith(
      filteredRecent: recentMatched,
      filteredAll: [...recentMatched, ...othersMatched],
    );
  }
}
