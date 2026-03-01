// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:easy_audio/easy_audio.dart' as _i709;
import 'package:example/core/di/record_flow_deps.dart' as _i219;
import 'package:example/data/datasources/fake_server_store.dart' as _i113;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final recordFlowDepsModule = _$RecordFlowDepsModule();
    gh.lazySingleton<_i709.PendingRecordingLocalDataSource>(
      () => recordFlowDepsModule.pendingRecordingLocalDataSource,
    );
    gh.lazySingleton<_i709.PendingRecordingRepository>(
      () => recordFlowDepsModule.pendingRecordingRepository(
        gh<_i709.PendingRecordingLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i709.PendingRecordingsUsecase>(
      () => recordFlowDepsModule.pendingRecordingsUsecase(
        gh<_i709.PendingRecordingRepository>(),
      ),
    );
    gh.lazySingleton<_i709.PendingUploadUsecase>(
      () => recordFlowDepsModule.pendingUploadUsecase(
        gh<_i709.PendingRecordingsUsecase>(),
      ),
    );
    gh.lazySingleton<_i709.PendingRecordingsBloc>(
      () => recordFlowDepsModule.pendingRecordingsBloc(
        gh<_i709.PendingRecordingsUsecase>(),
      ),
    );
    gh.lazySingleton<_i709.RecordSessionUsecase>(
      () => recordFlowDepsModule.recordSessionUsecase(
        gh<_i709.PendingRecordingsUsecase>(),
      ),
    );
    gh.lazySingleton<_i709.CrashRecoveryUsecase>(
      () => recordFlowDepsModule.crashRecoveryUsecase(
        gh<_i709.PendingRecordingsUsecase>(),
      ),
    );
    gh.lazySingleton<_i113.FakeServerStore>(
      () => recordFlowDepsModule.fakeServerStore(
        gh<_i709.PendingRecordingsUsecase>(),
      ),
    );
    gh.lazySingleton<_i709.PendingUploadOrchestratorBloc>(
      () => recordFlowDepsModule.pendingUploadOrchestrator(
        gh<_i709.PendingUploadUsecase>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i709.PendingUploadBloc>(
      () => recordFlowDepsModule.pendingUploadBloc(
        gh<_i709.PendingUploadOrchestratorBloc>(),
      ),
    );
    gh.lazySingleton<_i709.RecordSessionCubit>(
      () => recordFlowDepsModule.recordSessionCubit(
        gh<_i709.RecordSessionUsecase>(),
        gh<_i709.PendingUploadBloc>(),
      ),
    );
    gh.lazySingleton<_i709.CrashRecoveryBloc>(
      () => recordFlowDepsModule.crashRecoveryBloc(
        gh<_i709.CrashRecoveryUsecase>(),
        gh<_i709.PendingRecordingsUsecase>(),
        gh<_i709.PendingUploadBloc>(),
      ),
    );
    gh.lazySingleton<_i219.RecordFlowDeps>(
      () => _i219.RecordFlowDeps(
        pendingRecordingsUsecase: gh<_i709.PendingRecordingsUsecase>(),
        pendingUploadUsecase: gh<_i709.PendingUploadUsecase>(),
        pendingUploadOrchestrator: gh<_i709.PendingUploadOrchestratorBloc>(),
        pendingUploadBloc: gh<_i709.PendingUploadBloc>(),
        pendingRecordingsBloc: gh<_i709.PendingRecordingsBloc>(),
        recordSessionUsecase: gh<_i709.RecordSessionUsecase>(),
        recordSessionCubit: gh<_i709.RecordSessionCubit>(),
        crashRecoveryUsecase: gh<_i709.CrashRecoveryUsecase>(),
        crashRecoveryBloc: gh<_i709.CrashRecoveryBloc>(),
        fakeServerStore: gh<_i113.FakeServerStore>(),
      ),
    );
    return this;
  }
}

class _$RecordFlowDepsModule extends _i219.RecordFlowDepsModule {}
