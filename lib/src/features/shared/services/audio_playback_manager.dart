import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/entities/audio_playback_snapshot.dart';

class AudioPlaybackManager {
  AudioPlaybackManager._();

  static final AudioPlaybackManager instance = AudioPlaybackManager._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<AudioPlaybackSnapshot> snapshot =
      ValueNotifier<AudioPlaybackSnapshot>(AudioPlaybackSnapshot.empty);

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  bool _initialized = false;
  Future<void>? _setUrlInFlight;
  int _loadToken = 0;

  Future<Directory> _getCacheDir() async {
    final baseDir = await getTemporaryDirectory();
    final dir = Directory('${baseDir.path}/audio_cache');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  String _cacheKeyForUrl(String url) {
    final encoded = base64UrlEncode(utf8.encode(url)).replaceAll('=', '');
    final trimmed = encoded.length > 64 ? encoded.substring(0, 64) : encoded;
    return '${trimmed}_${url.hashCode.abs()}';
  }

  String _extensionFromUrl(Uri uri) {
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final idx = last.lastIndexOf('.');
    if (idx == -1 || idx == last.length - 1) {
      return '';
    }
    final ext = last.substring(idx).toLowerCase();
    return ext.length > 6 ? '' : ext;
  }

  bool _isNonAudioExtension(String ext) {
    switch (ext) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
      case '.gif':
      case '.svg':
      case '.bmp':
      case '.json':
      case '.txt':
      case '.pdf':
        return true;
      default:
        return false;
    }
  }

  String _extensionFromContentType(String? mime) {
    switch (mime) {
      case 'audio/mpeg':
      case 'audio/mp3':
      case 'audio/x-mp3':
        return '.mp3';
      case 'audio/mp4':
      case 'audio/x-m4a':
      case 'audio/aac':
        return '.m4a';
      case 'audio/wav':
      case 'audio/x-wav':
        return '.wav';
      case 'audio/ogg':
      case 'audio/opus':
        return '.ogg';
      case 'audio/flac':
        return '.flac';
      default:
        return '';
    }
  }

  String _extensionFromContentDisposition(String? disposition) {
    if (disposition == null || disposition.isEmpty) {
      return '';
    }
    final match = RegExp(
      "filename\\*=UTF-8''([^;]+)|filename=\"?([^\";]+)\"?",
    ).firstMatch(disposition);
    final filename = match?.group(1) ?? match?.group(2);
    if (filename == null || filename.isEmpty) {
      return '';
    }
    final idx = filename.lastIndexOf('.');
    if (idx == -1 || idx == filename.length - 1) {
      return '';
    }
    final ext = filename.substring(idx).toLowerCase();
    return ext.length > 6 ? '' : ext;
  }

  String _resolveExtension(Uri uri, HttpClientResponse response) {
    final byDisposition = _extensionFromContentDisposition(
      response.headers.value('content-disposition'),
    );
    if (byDisposition.isNotEmpty) {
      return byDisposition;
    }
    final byType = _extensionFromContentType(
      response.headers.contentType?.mimeType.toLowerCase(),
    );
    if (byType.isNotEmpty) {
      return byType;
    }
    final byUrl = _extensionFromUrl(uri);
    if (byUrl.isNotEmpty) {
      return byUrl;
    }
    return '.m4a';
  }

  File? _findCachedFile(Directory cacheDir, String baseName) {
    try {
      final items = cacheDir.listSync().whereType<File>();
      for (final file in items) {
        final name = file.uri.pathSegments.last;
        if (name.startsWith(baseName) && file.existsSync()) {
          final len = file.lengthSync();
          if (len > 0) {
            return file;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<File?> _getCachedFileForUrl(String url, int loadToken) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    final extFromUrl = _extensionFromUrl(uri);
    if (extFromUrl.isNotEmpty && _isNonAudioExtension(extFromUrl)) {
      return null;
    }

    final cacheDir = await _getCacheDir();
    final baseName = _cacheKeyForUrl(url);

    final existing = _findCachedFile(cacheDir, baseName);
    if (existing != null) {
      return existing;
    }

    final client = HttpClient();
    try {
      if (loadToken != _loadToken) {
        return null;
      }
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'audio/*');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      if (loadToken != _loadToken) {
        await response.drain();
        return null;
      }

      final mime = response.headers.contentType?.mimeType.toLowerCase();
      final isAudio = mime?.startsWith('audio/') ?? false;
      final isOctet =
          mime == 'application/octet-stream' || mime == 'binary/octet-stream';
      if (!isAudio && !isOctet) {
        await response.drain();
        return null;
      }

      if (response.contentLength == 0) {
        await response.drain();
        return null;
      }

      final ext = _resolveExtension(uri, response);
      final finalPath = '${cacheDir.path}/$baseName$ext';
      final tmpPath = '${cacheDir.path}/$baseName.download';
      final tmpFile = File(tmpPath);

      final sink = tmpFile.openWrite();
      try {
        await sink.addStream(response);
      } finally {
        await sink.close();
      }
      if (tmpFile.existsSync() && tmpFile.lengthSync() > 0) {
        final finalFile = File(finalPath);
        if (finalFile.existsSync()) {
          try {
            finalFile.deleteSync();
          } catch (_) {}
        }
        try {
          await tmpFile.rename(finalPath);
        } catch (_) {
          return null;
        }
        return finalFile;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _setFilePathWithFallback(
    String filePath, {
    String? originalSourceForLogs,
  }) async {
    final f = File(filePath);
    if (!f.existsSync()) {
      throw StateError('File not found: $filePath');
    }

    final len = f.lengthSync();
    if (len <= 0) {
      throw StateError('File is empty: $filePath');
    }

    try {
      await _player.setFilePath(filePath);
      return;
    } catch (e) {
      final label = originalSourceForLogs ?? filePath;
      debugPrint('AudioPlaybackManager: setFilePath failed ($label): $e');
    }

    final tmpDir = await getTemporaryDirectory();
    final safeName = 'preview_${DateTime.now().microsecondsSinceEpoch}.m4a';
    final tmpPath = '${tmpDir.path}/$safeName';
    await f.copy(tmpPath);
    await _player.setFilePath(tmpPath);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _playerStateSub = _player.playerStateStream.listen((state) {
      final processing = state.processingState;
      final isLoading = processing == ProcessingState.loading ||
          processing == ProcessingState.buffering;

      snapshot.value = snapshot.value.copyWith(
        isPlaying: state.playing,
        isLoading: isLoading,
      );

      if (processing == ProcessingState.completed) {
        stop();
      }
    });

    _durationSub = _player.durationStream.listen((duration) {
      snapshot.value = snapshot.value.copyWith(duration: duration);
    });

    _positionSub = _player.positionStream.listen((pos) {
      snapshot.value = snapshot.value.copyWith(position: pos);
    });
  }

  Future<void> _setSource(String source, int loadToken) async {
    final uri = Uri.tryParse(source);

    if (uri != null && uri.scheme == 'file') {
      final filePath = uri.toFilePath();

      try {
        await _player.setUrl(source);
        return;
      } catch (_) {}

      await _setFilePathWithFallback(filePath, originalSourceForLogs: source);
      return;
    }

    if (uri == null || uri.scheme.isEmpty) {
      if (source.startsWith('/')) {
        try {
          await _setFilePathWithFallback(source);
          return;
        } catch (_) {}
      }

      try {
        if (File(source).existsSync()) {
          await _setFilePathWithFallback(source);
          return;
        }
      } catch (_) {}
    }

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final cachedFile = await _getCachedFileForUrl(source, loadToken);
      if (loadToken != _loadToken) {
        return;
      }
      if (cachedFile != null) {
        try {
          await _setFilePathWithFallback(
            cachedFile.path,
            originalSourceForLogs: source,
          );
          return;
        } catch (_) {
          try {
            if (cachedFile.existsSync()) {
              cachedFile.deleteSync();
            }
          } catch (_) {}
        }
      }
    }

    await _player.setUrl(source);
  }

  Future<void> playUrl(String url) async {
    await playSource(url);
  }

  Future<void> playSource(String source) async {
    if (source.isEmpty) {
      return;
    }
    await _ensureInitialized();

    final loadToken = ++_loadToken;

    final inflight = _setUrlInFlight;
    if (inflight != null) {
      await inflight;
    }

    try {
      if (snapshot.value.currentUrl != source) {
        snapshot.value = snapshot.value.copyWith(
          currentUrl: source,
          isLoading: true,
          isPlaying: false,
          position: Duration.zero,
          clearDuration: true,
        );

        _setUrlInFlight = _setSource(
          source,
          loadToken,
        ).then((_) {}).whenComplete(() => _setUrlInFlight = null);

        await _setUrlInFlight;
      }

      if (loadToken != _loadToken) {
        return;
      }

      await _player.play();
    } catch (e, trace) {
      debugPrint(
        'AudioPlaybackManager: Failed to play source "$source": $e \n$trace',
      );
      snapshot.value = snapshot.value.copyWith(
        isPlaying: false,
        isLoading: false,
        clearUrl: true,
        clearDuration: true,
        position: Duration.zero,
      );
    }
  }

  Future<void> toggleUrl(String url) async {
    await toggleSource(url);
  }

  Future<void> toggleSource(String source) async {
    if (source.isEmpty) {
      return;
    }
    await _ensureInitialized();

    final isActive = snapshot.value.currentUrl == source;
    if (isActive && _player.playing) {
      await pause();
      return;
    }

    await playSource(source);
  }

  Future<void> pause() async {
    if (!_initialized) {
      return;
    }
    await _player.pause();
  }

  Future<void> stop({bool clearUrl = true}) async {
    _loadToken++;
    if (!_initialized) {
      if (clearUrl) {
        snapshot.value = AudioPlaybackSnapshot.empty;
      }
      return;
    }

    await _player.stop();

    snapshot.value = snapshot.value.copyWith(
      isPlaying: false,
      isLoading: false,
      position: Duration.zero,
      clearUrl: clearUrl,
      clearDuration: clearUrl,
    );
  }

  Future<void> seek(Duration position) async {
    if (!_initialized) {
      return;
    }
    final target = position < Duration.zero ? Duration.zero : position;
    await _player.seek(target);
  }

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _player.dispose();
  }
}
