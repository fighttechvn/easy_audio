// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:easy_audio/easy_audio.dart' as _i709;
import 'package:example/core/di/record_flow_deps.dart' as _i940;
import 'package:example/data/datasources/fake_server_store.dart' as _i523;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  await _i709.EasyAudioPackageModule().init(gh);
  final recordFlowDepsModule = _$RecordFlowDepsModule();
  gh.lazySingleton<_i523.FakeServerStore>(
    () => recordFlowDepsModule.fakeServerStore(
      gh<_i709.PendingRecordingsUsecase>(),
    ),
  );
  return getIt;
}

class _$RecordFlowDepsModule extends _i940.RecordFlowDepsModule {}
