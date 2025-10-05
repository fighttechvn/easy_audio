// ---------------------------------------------------------------------------
// Speech-to-text only screen
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

class SpeechToTextOnlyScreen extends StatefulWidget {
  const SpeechToTextOnlyScreen({super.key});

  @override
  State<SpeechToTextOnlyScreen> createState() => _SpeechToTextOnlyScreenState();
}

class _SpeechToTextOnlyScreenState extends State<SpeechToTextOnlyScreen> {
  final SpeechToTextService _service = SpeechToTextService(sampleRate: 16000);
  final List<String> _finalSegments = <String>[];
  String _partialSegment = '';
  String _selectedLocale = RecordLanguage.defaultLocale;
  Map<String, String> _supportedLocales = RecordLanguage.supported;
  bool _isLoadingLocales = false;
  bool _isPrepared = false;
  bool _isRunning = false;
  String? _error;
  StreamSubscription<SpeechRecognitionResult>? _subscription;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
    unawaited(_loadSupportedLocales());
  }

  Future<void> _prepare() async {
    try {
      await _service.prepare();
      if (!mounted) return;
      setState(() => _isPrepared = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _start() async {
    if (!_isPrepared) {
      await _prepare();
      if (!_isPrepared) return;
    }
    await _service.start(localeId: _selectedLocale);
    _subscription ??= _service.results.listen(
      _handleResult,
      onError: (error) {
        if (!mounted) return;
        setState(() => _error = error.toString());
      },
    );
    if (!mounted) return;
    setState(() {
      _isRunning = true;
      _error = null;
    });
  }

  Future<void> _stop() async {
    await _service.stop();
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _partialSegment = '';
    });
  }

  Future<void> _loadSupportedLocales() async {
    if (mounted) {
      setState(() {
        _isLoadingLocales = true;
      });
    } else {
      _isLoadingLocales = true;
    }
    try {
      final locales = await RecordLanguage.ensureSystemLocalesLoaded();
      if (!mounted) {
        return;
      }
      final availableLocales = Map<String, String>.from(locales);
      final hasSelected = availableLocales.values.contains(_selectedLocale);
      setState(() {
        _supportedLocales = availableLocales;
        if (!hasSelected) {
          _selectedLocale = RecordLanguage.defaultLocale;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocales = false;
        });
      }
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      if (result.isFinal) {
        _finalSegments.add(result.text);
        _partialSegment = '';
      } else {
        _partialSegment = result.text;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(_service.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech to Text only')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Trạng thái: ${_isRunning ? 'Đang lắng nghe' : 'Đã dừng'}'),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngôn ngữ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocale,
                    isExpanded: true,
                    onChanged: _isRunning
                        ? null
                        : (String? value) {
                            if (value == null) return;
                            setState(() => _selectedLocale = value);
                          },
                    items: _supportedLocales.values
                        .map(
                          (locale) => DropdownMenuItem<String>(
                            value: locale,
                            child: Text(RecordLanguage.labelFor(locale)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            if (_isLoadingLocales)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRunning ? _stop : _start,
              icon: Icon(_isRunning ? Icons.stop : Icons.mic),
              label: Text(_isRunning ? 'Stop' : 'Start listening'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: <Widget>[
                    for (final String segment in _finalSegments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(segment),
                      ),
                    if (_partialSegment.isNotEmpty)
                      Text(
                        _partialSegment,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
