import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'domain/entities/language_selection.dart';
import 'domain/usecases/select_language_usecase.dart';
import 'features/select_language/cubit/select_language_cubit.dart';
import 'features/select_language/select_language_dialog.dart';
import 'integration/audio/easy_audio/easy_audio_service.dart';

extension EasyAudioCoordinator on BuildContext {
  Future<LanguageSelection?> openSelectLanguages(
    EasyAudioService easyAudioService,
  ) async {
    return showDialog<LanguageSelection>(
      context: this,
      builder: (context) => BlocProvider<SelectLanguageCubit>(
        create: (context) => SelectLanguageCubit(
          useCase: SelectLanguageUseCase(),
          easyAudio: easyAudioService,
        )..loadLocales(),
        child: const SelectLanguageDialogWidget(),
      ),
    );
  }
}
