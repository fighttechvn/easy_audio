/// Now-playing information surfaced on the iOS lock screen / Control Center and
/// in the Android media notification.
///
/// Kept separate from `MediaItem` so callers never have to depend on
/// `just_audio_background` or `audio_service` directly.
class AudioMetadata {
  const AudioMetadata({
    required this.title,
    this.album,
    this.artist,
    this.artUri,
  });

  final String title;
  final String? album;
  final String? artist;
  final Uri? artUri;
}
