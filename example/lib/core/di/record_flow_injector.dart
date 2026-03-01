import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'record_flow_injector.config.dart';

final GetIt injector = GetIt.asNewInstance();

bool _configured = false;

@InjectableInit()
void configureRecordFlowInjector() {
  if (_configured) {
    return;
  }
  _configured = true;
  injector.init();
}
