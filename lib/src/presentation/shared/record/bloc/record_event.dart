part of 'record_bloc.dart';

@immutable
sealed class RecordEvent {}

// ============ Language Events ============

class RecordLoadSupportedLanguagesEvent extends RecordEvent {
  RecordLoadSupportedLanguagesEvent({
    required this.currentLocale,
    this.recordAfterLoaded = false,
  });

  final String currentLocale;
  final bool recordAfterLoaded;
}

class RecordResetStateEvent extends RecordEvent {
  RecordResetStateEvent();
}

class RecordPrepareLanguageModelEvent extends RecordEvent {
  RecordPrepareLanguageModelEvent({
    required this.locale,
  });

  final String locale;
}

// ============ Audio Player Events ============

/// Initialize audio player and add listener
class InitAudioPlayerEvent extends RecordEvent {
  InitAudioPlayerEvent();
}

/// Dispose audio player and remove listener
class DisposeAudioPlayerEvent extends RecordEvent {
  DisposeAudioPlayerEvent();
}

/// Play audio by url. If url is empty or null, stop current audio.
class PlayAudioEvent extends RecordEvent {
  PlayAudioEvent({this.url});

  final String? url;
}

/// Stop audio player
class StopAudioEvent extends RecordEvent {
  StopAudioEvent();
}

/// Internal event: Audio state changed from controller listener
class AudioStateChangedEvent extends RecordEvent {
  AudioStateChangedEvent({
    required this.isPlaying,
    required this.isOpenPlayer,
    required this.currentPlayingUrl,
  });

  final bool isPlaying;
  final bool isOpenPlayer;
  final String currentPlayingUrl;
}

// ============ Recording Events ============

class RecordingAudioEvent extends RecordEvent {
  RecordingAudioEvent();
}

class RecordAudioDoneEvent extends RecordEvent {
  RecordAudioDoneEvent();
}

// ============ Audio List Events ============

/// Add a single audio item to the list
class AddAudioItemEvent<A> extends RecordEvent {
  AddAudioItemEvent(this.item);

  final A item;
}

/// Merge multiple audio items to the list (without duplicates)
class MergeAudioItemsEvent<A> extends RecordEvent {
  MergeAudioItemsEvent(
    this.items, {
    this.isDuplicate,
  });

  final List<A> items;
  final bool Function(dynamic existing, dynamic newItem)? isDuplicate;
}

/// Clear audio list
class ClearAudioListEvent extends RecordEvent {
  ClearAudioListEvent();
}
