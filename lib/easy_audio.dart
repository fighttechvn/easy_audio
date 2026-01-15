library;

export 'package:record/record.dart' show AudioEncoder, AndroidService;

export 'src/core/constants/easy_audio_locale_display.dart';
export 'src/core/controllers/elapsed_ticker.dart';
export 'src/core/errors/easy_audio_exception.dart';
export 'src/domain/entities/audio_playback_snapshot.dart';
export 'src/domain/entities/easy_audio_config.dart';
export 'src/domain/entities/easy_audio_mode.dart';
export 'src/domain/entities/easy_audio_state.dart';
export 'src/domain/entities/language_selection.dart';
export 'src/domain/entities/recording_result.dart';
export 'src/domain/entities/select_language_data.dart';
export 'src/domain/entities/supported_locale.dart';
export 'src/domain/entities/transcript_result.dart';
export 'src/domain/usecases/select_language_usecase.dart';
export 'src/easy_audio_coordinator.dart';
export 'src/features/shared/services/audio_playback_manager.dart';
export 'src/features/shared/services/easy_audio/easy_audio_service.dart';
export 'src/features/shared/services/easy_audio/easy_audio_service_interface.dart';
export 'src/features/shared/ui/waveform_painter.dart';
