import 'package:easy_audio/easy_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/easy_audio_repository_impl.dart';
import '../../../domain/usecases/easy_audio_usecase.dart';
import '../../../domain/usecases/playback_usecase.dart';
import 'easy_audio_manage/easy_audio_manage_bloc.dart';
import 'playback/playback_bloc.dart';
import 'recording/recording_bloc.dart';

export 'easy_audio_manage/easy_audio_manage_bloc.dart';
export 'playback/playback_bloc.dart';
export 'recording/recording_bloc.dart';

/// HomeBloc là coordinator, quản lý và kết nối các bloc con
class HomeBloc extends Cubit<void> {
  HomeBloc._({
    required this.easyAudioManageBloc,
    required this.recordingBloc,
    required this.playbackBloc,
  }) : super(null) {
    _setupCallbacks();
  }

  /// Factory constructor để tạo HomeBloc với tất cả dependencies
  factory HomeBloc.create() {
    final service = EasyAudioService();
    final repository = EasyAudioRepositoryImpl(service: service);
    final easyAudioUseCase = EasyAudioUseCase(repository: repository);
    final playbackUseCase = PlaybackUseCase();

    final easyAudioManageBloc = EasyAudioManageBloc(useCase: easyAudioUseCase);
    final recordingBloc = RecordingBloc(useCase: easyAudioUseCase);
    final playbackBloc = PlaybackBloc(useCase: playbackUseCase);

    return HomeBloc._(
      easyAudioManageBloc: easyAudioManageBloc,
      recordingBloc: recordingBloc,
      playbackBloc: playbackBloc,
    );
  }

  final EasyAudioManageBloc easyAudioManageBloc;
  final RecordingBloc recordingBloc;
  final PlaybackBloc playbackBloc;

  void _setupCallbacks() {
    // When EasyAudio is initialized, setup recording subscriptions
    easyAudioManageBloc.onInitialized = recordingBloc.setupSubscriptions;

    easyAudioManageBloc.onModeChanging = () {
      playbackBloc.add(const PlaybackClosed());
    };
  }

  /// Start the home - initialize EasyAudio
  void start() {
    easyAudioManageBloc.add(const EasyAudioManageStarted());
  }

  @override
  Future<void> close() async {
    await easyAudioManageBloc.close();
    await recordingBloc.close();
    await playbackBloc.close();
    return super.close();
  }
}
