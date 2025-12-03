library;

export 'package:floating_draggable_widget/floating_draggable_widget.dart';
export 'package:record/record.dart'
    show AudioInterruptionMode, IosRecordConfig, IosAudioCategoryOption;
export 'package:speech_to_text_record/speech_to_text_record.dart';

export 'src/core/dialog_coodinator.dart';
export 'src/core/services/easy_audio_controller.dart';
export 'src/core/services/language_history_service.dart';
export 'src/core/services/record_modal_service.dart';
export 'src/domain/entities/process_player.dart';
export 'src/domain/entities/record_data.dart';
export 'src/domain/entities/record_language_result.dart';
export 'src/domain/usecase/record_usecase.dart';
export 'src/domain/usecase/speech_to_text_usecase.dart';
export 'src/presentation/mixins/base_record_session_mixin.dart';
export 'src/presentation/record_modal/bloc/speech_text_bloc.dart';
export 'src/presentation/record_modal/record_modal_widget.dart';
export 'src/presentation/record_modal/record_session_manager.dart';
export 'src/presentation/record_modal/widgets/floating_record_widget.dart';
export 'src/presentation/select_language/select_languague_dialog_widget.dart';
export 'src/presentation/shared/record/bloc/record_bloc.dart';
export 'src/presentation/shared/record/entities/record_state_ui.dart';
export 'src/presentation/shared/widgets/easy_audio_player.dart';
export 'src/presentation/shared/widgets/record_floating_overlay_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/wareforms_sourd_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/waveforms_animation_widget.dart';
export 'src/presentation/shared/widgets/waveforms_sound/waveforms_sound_constants.dart';
export 'src/record_audio_coodinator.dart';
