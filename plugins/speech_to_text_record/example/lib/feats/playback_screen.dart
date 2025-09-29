// ---------------------------------------------------------------------------
// Playback screen
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _loading = true;
  String? _error;
  List<FileSystemEntity> _files = <FileSystemEntity>[];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      final bool playing =
          state.playing && state.processingState != ProcessingState.completed;
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });
    unawaited(_configureSession());
    unawaited(_loadFiles());
  }

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final entries = await dir
          .list()
          .where(
            (entity) =>
                entity is File && entity.path.toLowerCase().endsWith('.wav'),
          )
          .toList();
      entries.sort((a, b) {
        final aTime = (a as File).lastModifiedSync();
        final bTime = (b as File).lastModifiedSync();
        return bTime.compareTo(aTime);
      });
      if (!mounted) return;
      setState(() {
        _files = entries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể đọc thư mục: $error';
        _loading = false;
      });
    }
  }

  Future<void> _play(File file) async {
    if (_isPlaying) {
      await _player.stop();
    }
    try {
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không thể phát tệp: $error');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback recordings'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_files.isEmpty)
              const Expanded(child: Center(child: Text('Chưa có bản ghi nào.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final file = _files[index] as File;
                    final modified = file.lastModifiedSync();
                    return ListTile(
                      title: Text(file.path.split('/').last),
                      subtitle: Text(
                        'Cập nhật: ${modified.toLocal().toIso8601String()}',
                      ),
                      trailing: const Icon(Icons.play_arrow),
                      onTap: () => _play(file),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _isPlaying
          ? FloatingActionButton(
              onPressed: () async => _player.stop(),
              child: const Icon(Icons.stop),
            )
          : null,
    );
  }
}
