import 'package:flutter/foundation.dart';

@immutable
class RecordStateUI<T, A> {
  final String? currentLocale;
  final String? currentLanguageLabel;
  final T? data;
  final bool recordAfterLoaded;

  // Audio player state
  final bool isAudioPlayerInited;
  final bool isPlaying;
  final bool isOpenPlayer;
  final String? currentPlayingUrl;

  // Audio list state
  final List<A> audioList;

  const RecordStateUI({
    this.currentLocale,
    this.currentLanguageLabel,
    this.data,
    this.recordAfterLoaded = false,
    this.isAudioPlayerInited = false,
    this.isPlaying = false,
    this.isOpenPlayer = false,
    this.currentPlayingUrl,
    this.audioList = const [],
  });

  const RecordStateUI.initial()
      : currentLocale = null,
        currentLanguageLabel = null,
        data = null,
        recordAfterLoaded = false,
        isAudioPlayerInited = false,
        isPlaying = false,
        isOpenPlayer = false,
        currentPlayingUrl = null,
        audioList = const [];

  bool get isLanguageLoaded => currentLocale != null;

  RecordStateUI<T, A> copyWith({
    String? currentLocale,
    String? currentLanguageLabel,
    T? data,
    bool? recordAfterLoaded,
    bool? isAudioPlayerInited,
    bool? isPlaying,
    bool? isOpenPlayer,
    String? currentPlayingUrl,
    List<A>? audioList,
  }) {
    return RecordStateUI<T, A>(
      currentLocale: currentLocale ?? this.currentLocale,
      currentLanguageLabel: currentLanguageLabel ?? this.currentLanguageLabel,
      data: data ?? this.data,
      recordAfterLoaded: recordAfterLoaded ?? this.recordAfterLoaded,
      isAudioPlayerInited: isAudioPlayerInited ?? this.isAudioPlayerInited,
      isPlaying: isPlaying ?? this.isPlaying,
      isOpenPlayer: isOpenPlayer ?? this.isOpenPlayer,
      currentPlayingUrl: currentPlayingUrl ?? this.currentPlayingUrl,
      audioList: audioList ?? this.audioList,
    );
  }

  RecordStateUI<T, A> resetRecordAfterLoaded() {
    return RecordStateUI<T, A>(
      currentLocale: currentLocale,
      currentLanguageLabel: currentLanguageLabel,
      data: data,
      recordAfterLoaded: false,
      isAudioPlayerInited: isAudioPlayerInited,
      isPlaying: isPlaying,
      isOpenPlayer: isOpenPlayer,
      currentPlayingUrl: currentPlayingUrl,
      audioList: audioList,
    );
  }

  RecordStateUI<T, A> updateAudioState({
    bool? isPlaying,
    bool? isOpenPlayer,
    String? currentPlayingUrl,
  }) {
    return RecordStateUI<T, A>(
      currentLocale: currentLocale,
      currentLanguageLabel: currentLanguageLabel,
      data: data,
      recordAfterLoaded: recordAfterLoaded,
      isAudioPlayerInited: isAudioPlayerInited,
      isPlaying: isPlaying ?? this.isPlaying,
      isOpenPlayer: isOpenPlayer ?? this.isOpenPlayer,
      currentPlayingUrl: currentPlayingUrl ?? this.currentPlayingUrl,
      audioList: audioList,
    );
  }

  /// Add a single audio item to the list
  RecordStateUI<T, A> addAudioItem(A item) {
    return copyWith(audioList: [...audioList, item]);
  }

  /// Add multiple audio items to the list (merge without duplicates)
  RecordStateUI<T, A> mergeAudioItems(
    List<A> items, {
    bool Function(A existing, A newItem)? isDuplicate,
  }) {
    if (isDuplicate == null) {
      return copyWith(audioList: [...audioList, ...items]);
    }

    final mergedList = [...audioList];
    for (final item in items) {
      final exists = mergedList.any((existing) => isDuplicate(existing, item));
      if (!exists) {
        mergedList.add(item);
      }
    }
    return copyWith(audioList: mergedList);
  }

  /// Clear audio list
  RecordStateUI<T, A> clearAudioList() {
    return copyWith(audioList: []);
  }
}
