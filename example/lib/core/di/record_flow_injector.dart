import 'package:easy_audio/easy_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'record_flow_injector.config.dart';

final GetIt injector = GetIt.asNewInstance();

@InjectableInit(
  initializerName: 'init', // default
  // preferRelativeImports: true, // default
  asExtension: false, // default
  externalPackageModulesBefore: [ExternalModule(EasyAudioPackageModule)],
)
Future<void> configureDependencies({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async => init(
  injector,
  environment: environment,
  environmentFilter: environmentFilter,
);
