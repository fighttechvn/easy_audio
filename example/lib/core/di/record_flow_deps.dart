import 'dart:async';

import 'package:easy_audio/easy_audio.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/fake_server_store.dart';

@module
abstract class RecordFlowDepsModule {
  @lazySingleton
  PendingRecordingLocalDataSource get pendingRecordingLocalDataSource =>
      PendingRecordingLocalDataSource();

  @lazySingleton
  PendingRecordingRepository pendingRecordingRepository(
    PendingRecordingLocalDataSource local,
  ) => PendingRecordingRepositoryImpl(local: local);

  @lazySingleton
  PendingRecordingsUsecase pendingRecordingsUsecase(
    PendingRecordingRepository repository,
  ) => PendingRecordingsUsecase(repository);

  @lazySingleton
  PendingUploadUsecase pendingUploadUsecase(PendingRecordingsUsecase usecase) =>
      PendingUploadUsecase(usecase);

  @lazySingleton
  PendingUploadOrchestratorBloc pendingUploadOrchestrator(
    PendingUploadUsecase usecase,
  ) => PendingUploadOrchestratorBloc(usecase);

  @lazySingleton
  PendingUploadBloc pendingUploadBloc(
    PendingUploadOrchestratorBloc orchestrator,
  ) => PendingUploadBloc(orchestrator);

  @lazySingleton
  PendingRecordingsBloc pendingRecordingsBloc(
    PendingRecordingsUsecase usecase,
  ) => PendingRecordingsBloc(usecase);

  @lazySingleton
  RecordSessionUsecase recordSessionUsecase(PendingRecordingsUsecase usecase) =>
      RecordSessionUsecase(usecase);

  @lazySingleton
  RecordSessionCubit recordSessionCubit(
    RecordSessionUsecase usecase,
    PendingUploadBloc pendingUploadBloc,
  ) => RecordSessionCubit(usecase, pendingUploadBloc);

  @lazySingleton
  CrashRecoveryUsecase crashRecoveryUsecase(PendingRecordingsUsecase usecase) =>
      CrashRecoveryUsecase(usecase);

  @lazySingleton
  CrashRecoveryBloc crashRecoveryBloc(
    CrashRecoveryUsecase crashRecoveryUsecase,
    PendingRecordingsUsecase pendingRecordingsUsecase,
    PendingUploadBloc pendingUploadBloc,
  ) => CrashRecoveryBloc(
    crashRecoveryUsecase,
    pendingRecordingsUsecase,
    pendingUploadBloc,
  );

  @lazySingleton
  FakeServerStore fakeServerStore(PendingRecordingsUsecase usecase) =>
      FakeServerStore(usecase);
}

@lazySingleton
class RecordFlowDeps {
  RecordFlowDeps({
    required this.pendingRecordingsUsecase,
    required this.pendingUploadUsecase,
    required this.pendingUploadOrchestrator,
    required this.pendingUploadBloc,
    required this.pendingRecordingsBloc,
    required this.recordSessionUsecase,
    required this.recordSessionCubit,
    required this.crashRecoveryUsecase,
    required this.crashRecoveryBloc,
    required this.fakeServerStore,
  }) {
    pendingUploadOrchestrator.setUploadRecordingProgressCallback(
      fakeServerStore.uploadAndPersistCopy,
    );
  }

  final PendingRecordingsUsecase pendingRecordingsUsecase;
  final PendingUploadUsecase pendingUploadUsecase;
  final PendingUploadOrchestratorBloc pendingUploadOrchestrator;
  final PendingUploadBloc pendingUploadBloc;
  final PendingRecordingsBloc pendingRecordingsBloc;

  final RecordSessionUsecase recordSessionUsecase;
  final RecordSessionCubit recordSessionCubit;

  final CrashRecoveryUsecase crashRecoveryUsecase;
  final CrashRecoveryBloc crashRecoveryBloc;

  final FakeServerStore fakeServerStore;

  void dispose() {
    unawaited(recordSessionCubit.close());
    unawaited(crashRecoveryBloc.close());
    unawaited(pendingUploadBloc.close());
    unawaited(pendingUploadOrchestrator.close());
    unawaited(pendingRecordingsBloc.close());
  }
}
