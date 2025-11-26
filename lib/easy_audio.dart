library;

export 'package:floating_draggable_widget/floating_draggable_widget.dart';
export 'package:record/record.dart'
    show AudioInterruptionMode, IosRecordConfig, IosAudioCategoryOption;
export 'package:speech_to_text_record/speech_to_text_record.dart';

// Application layer - Configuration & Callbacks
// Core layer - Services & Coordinators
export 'src/core/dialog_coodinator.dart';
export 'src/core/easy_record_coordinator.dart';
export 'src/core/services/easy_audio_controller.dart';
export 'src/core/services/language_history_service.dart';
export 'src/core/services/record_modal_service.dart';
export 'src/domain/entities/easy_record_callbacks.dart';
export 'src/domain/entities/easy_record_configuration.dart';
// Domain layer - Entities & UseCases
export 'src/domain/entities/process_player.dart';
export 'src/domain/entities/record_data.dart';
export 'src/domain/entities/record_language_result.dart';
export 'src/domain/entities/record_session_data.dart';
export 'src/domain/usecase/record_usecase.dart';
export 'src/domain/usecase/speech_to_text_usecase.dart';
// Presentation layer - Floating Overlay
export 'src/presentation/floating_overlay/easy_record_floating_overlay.dart';
// Presentation layer - Language Selection
export 'src/presentation/language_selection/bloc/language_bloc.dart';
// Presentation layer - Record Modal
export 'src/presentation/record_modal/bloc/speech_text_bloc.dart';
export 'src/presentation/record_modal/record_modal_widget.dart';
export 'src/presentation/record_modal/record_session_manager.dart';
export 'src/presentation/record_modal/widgets/floating_record_widget.dart';
export 'src/presentation/select_language/select_languague_dialog_widget.dart';
// Presentation layer - Shared Widgets
export 'src/presentation/shared/widgets/easy_audio_player.dart';
export 'src/presentation/shared/widgets/waveforms_sound/wareforms_sourd_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/waveforms_animation_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/waveforms_sound_constants.dart';
// Legacy coordinator (for backward compatibility)
export 'src/record_audio_coodinator.dart';
