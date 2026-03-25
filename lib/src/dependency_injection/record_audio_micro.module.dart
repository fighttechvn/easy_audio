//@GeneratedMicroModule;EasyAudioPackageModule;package:easy_audio/src/dependency_injection/record_audio_micro.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:easy_audio/src/data/datasources/pending_recording_local_datasource.dart'
    as _i212;
import 'package:easy_audio/src/data/repository/pending_recording_repository.impl.dart'
    as _i389;
import 'package:easy_audio/src/domain/repository/pending_recording_repository.dart'
    as _i199;
import 'package:easy_audio/src/domain/usecases/pending_recordings_usecase.dart'
    as _i353;
import 'package:easy_audio/src/domain/usecases/pending_upload_usecase.dart'
    as _i1022;
import 'package:easy_audio/src/domain/usecases/recording/crash_recovery_usecase.dart'
    as _i42;
import 'package:easy_audio/src/domain/usecases/recording/record_session_usecase.dart'
    as _i1014;
import 'package:easy_audio/src/features/crash_recovery/crash_recovery_bloc.dart'
    as _i1055;
import 'package:easy_audio/src/features/pending_recordings/pending_recordings_bloc.dart'
    as _i1024;
import 'package:easy_audio/src/features/pending_upload/pending_upload_bloc.dart'
    as _i585;
import 'package:easy_audio/src/features/pending_upload_orchestrator/pending_upload_orchestrator_bloc.dart'
    as _i401;
import 'package:easy_audio/src/features/record_session/record_session_cubit.dart'
    as _i208;
import 'package:injectable/injectable.dart' as _i526;

class EasyAudioPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i212.PendingRecordingLocalDataSource>(
        () => _i212.PendingRecordingLocalDataSource());
    gh.lazySingleton<_i199.PendingRecordingRepository>(() =>
        _i389.PendingRecordingRepositoryImpl(
            local: gh<_i212.PendingRecordingLocalDataSource>()));
    gh.factory<_i353.PendingRecordingsUsecase>(() =>
        _i353.PendingRecordingsUsecase(gh<_i199.PendingRecordingRepository>()));
    gh.factory<_i1022.PendingUploadUsecase>(() =>
        _i1022.PendingUploadUsecase(gh<_i353.PendingRecordingsUsecase>()));
    gh.factory<_i42.CrashRecoveryUsecase>(
        () => _i42.CrashRecoveryUsecase(gh<_i353.PendingRecordingsUsecase>()));
    gh.factory<_i1014.RecordSessionUsecase>(() =>
        _i1014.RecordSessionUsecase(gh<_i353.PendingRecordingsUsecase>()));
    gh.factory<_i1024.PendingRecordingsBloc>(() =>
        _i1024.PendingRecordingsBloc(gh<_i353.PendingRecordingsUsecase>()));
    gh.lazySingleton<_i401.PendingUploadOrchestratorBloc>(
      () => _i401.PendingUploadOrchestratorBloc(
          gh<_i1022.PendingUploadUsecase>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i585.PendingUploadBloc>(() =>
        _i585.PendingUploadBloc(gh<_i401.PendingUploadOrchestratorBloc>()));
    gh.lazySingleton<_i1055.CrashRecoveryBloc>(() => _i1055.CrashRecoveryBloc(
          gh<_i42.CrashRecoveryUsecase>(),
          gh<_i353.PendingRecordingsUsecase>(),
          gh<_i585.PendingUploadBloc>(),
        ));
    gh.lazySingleton<_i208.RecordSessionCubit>(() => _i208.RecordSessionCubit(
          gh<_i1014.RecordSessionUsecase>(),
          gh<_i585.PendingUploadBloc>(),
        ));
  }
}
