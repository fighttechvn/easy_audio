library;

// third-party re-exports
export 'package:floating_draggable_widget/floating_draggable_widget.dart';
export 'package:record/record.dart'
    show AudioInterruptionMode, IosRecordConfig, IosAudioCategoryOption;
export 'package:speech_to_text_record/speech_to_text_record.dart';

// Core Services
export 'src/core/dialog_coodinator.dart';
// Presentation - Mixins
export 'src/core/mixins/base_record_session_mixin.dart';
// Simple mixin
export 'src/core/mixins/simple_record_mixin.dart';
export 'src/core/services/easy_audio_controller.dart';
export 'src/core/services/language_history_service.dart';
export 'src/core/services/pending_recording_service.dart';
export 'src/core/services/record_modal_service.dart';
// Domain Entities
export 'src/domain/entities/process_player.dart';
export 'src/domain/entities/record_data.dart';
export 'src/domain/entities/record_language_result.dart';
// Domain Usecases
export 'src/domain/usecase/record_usecase.dart';
export 'src/domain/usecase/speech_to_text_usecase.dart';
// Presentation - Widgets
export 'src/presentation/pending_recovery/pending_recording_recovery_widget.dart';
export 'src/presentation/record_modal/bloc/speech_text_bloc.dart';
export 'src/presentation/record_modal/record_modal_widget.dart';
export 'src/presentation/record_modal/record_session_manager.dart';
export 'src/presentation/record_modal/widgets/floating_record_widget.dart';
export 'src/presentation/select_language/select_languague_dialog_widget.dart';
export 'src/presentation/shared/record/bloc/record_bloc.dart';
export 'src/presentation/shared/record/entities/record_state_ui.dart';
export 'src/presentation/shared/widgets/easy_audio_player.dart';
export 'src/presentation/shared/widgets/record_floating_overlay_widget.dart';
// shared widgets
export 'src/presentation/shared/widgets/simple_audio_player.dart';
export 'src/presentation/shared/widgets/waveforms_sound/wareforms_sourd_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/waveforms_animation_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/waveforms_sound_constants.dart';
// Use these for simple use cases. For advanced usage, see the full API below.
export 'src/presentation/simple_api/easy_audio.dart';
export 'src/presentation/simple_api/easy_audio_config.dart';
export 'src/presentation/simple_api/easy_audio_localizations.dart';
export 'src/presentation/simple_api/easy_audio_theme.dart';
// Coordinator
export 'src/record_audio_coodinator.dart';
