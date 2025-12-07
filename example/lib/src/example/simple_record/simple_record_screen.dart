import 'dart:io';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'widgets/language_picker_dialog.dart';
import 'widgets/record_info_card.dart';
import 'widgets/recording_list_item.dart';

class SimpleRecordScreen extends StatefulWidget {
  const SimpleRecordScreen({super.key});

  @override
  State<SimpleRecordScreen> createState() => _SimpleRecordScreenState();
}

class _SimpleRecordScreenState extends State<SimpleRecordScreen>
    with SimpleRecordMixin {
  final List<RecordData> _recordings = [];
  bool _isRecording = false;
  String _selectedLocale = 'en-US';
  String _selectedLanguageLabel = 'English (United States)';

  @override
  Future<void> onRecordComplete(RecordData result) async {
    setState(() {
      _recordings.insert(0, result);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording saved! Duration: ${result.totalTime}ms'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.speech,
    ].request();

    return statuses[Permission.microphone] == PermissionStatus.granted &&
        statuses[Permission.speech] == PermissionStatus.granted;
  }

  @override
  String get currentLocale => _selectedLocale;

  /// Full recording flow following easy_audio_integration pattern:
  /// 1. Load supported languages (if not loaded)
  /// 2. Show language picker dialog
  /// 3. Select language
  /// 4. Start recording with selected language
  Future<void> _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
    });

    try {
      // Step 1: Load supported languages
      final languages = await _loadLanguagesWithLoading();
      if (!mounted || languages == null || languages.isEmpty) {
        return;
      }

      // Step 2: Show language picker dialog
      final selected = await showDialog<MapEntry<String, String>>(
        context: context,
        barrierDismissible: true,
        builder: (context) => LanguagePickerDialog(
          currentLocale: _selectedLocale,
          preloadedLanguages: languages,
        ),
      );

      // User cancelled
      if (selected == null || !mounted) {
        return;
      }

      // Step 3: Update selected language
      setState(() {
        _selectedLocale = selected.value;
        _selectedLanguageLabel = selected.key;
      });

      // Step 4: Start recording with selected language
      await startRecording();
    } catch (e) {
      debugPrint('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  /// Load supported languages with loading indicator
  Future<Map<String, String>?> _loadLanguagesWithLoading() async {
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Loading languages...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Load languages
      final languages = await RecordLanguage.ensureSystemLocalesLoaded();

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      return languages;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load languages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _deleteRecording(int index) async {
    final recording = _recordings[index];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete file
    try {
      final file = File(recording.url);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }

    // Remove from list
    setState(() {
      _recordings.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording deleted'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Audio - Simple API'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Info card
          RecordInfoCard(selectedLanguageLabel: _selectedLanguageLabel),

          // Recordings list
          Expanded(
            child: _recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recordings yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the microphone button to start',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      return RecordingListItem(
                        index: index,
                        recording: _recordings[index],
                        onDelete: () => _deleteRecording(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRecording ? null : _startRecording,
        icon: _isRecording
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.mic),
        label: Text(_isRecording ? 'Recording...' : 'Record'),
        backgroundColor: _isRecording ? Colors.grey : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
