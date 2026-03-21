
import 'package:easy_audio/easy_audio.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/fake_server_store.dart';

@module
abstract class RecordFlowDepsModule {
  @lazySingleton
  FakeServerStore fakeServerStore(PendingRecordingsUsecase usecase) =>
      FakeServerStore(usecase);
}
