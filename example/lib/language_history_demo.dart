import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

/// Demo screen to test language history functionality
class LanguageHistoryDemo extends StatefulWidget {
  const LanguageHistoryDemo({super.key});

  @override
  State<LanguageHistoryDemo> createState() => _LanguageHistoryDemoState();
}

class _LanguageHistoryDemoState extends State<LanguageHistoryDemo> {
  String? _selectedLanguage;
  List<String> _recentLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadRecentLanguages();
  }

  Future<void> _loadRecentLanguages() async {
    try {
      final recent = await LanguageHistoryService.getRecentlyUsedLanguages();
      setState(() {
        _recentLanguages = recent;
      });
    } catch (e) {
      debugPrint('Error loading recent languages: $e');
    }
  }

  Future<void> _selectLanguage() async {
    final result = await context.startSelectLanguague();
    if (result != null) {
      setState(() {
        _selectedLanguage = result;
      });
      // Reload recent languages to see the updated order
      await _loadRecentLanguages();
    }
  }

  Future<void> _clearHistory() async {
    await LanguageHistoryService.clearHistory();
    await _loadRecentLanguages();
    setState(() {
      _selectedLanguage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language History Demo'),
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Language:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLanguage ?? 'None selected',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Languages (Most Recent First):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_recentLanguages.isEmpty)
                      const Text(
                        'No recent languages',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...(_recentLanguages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final language = entry.value;
                        final languageName =
                            RecordLanguage.supported[language] ?? language;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$languageName ($language)',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      })),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectLanguage,
              icon: const Icon(Icons.language),
              label: const Text('Select Language'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• On iOS: Languages are saved when selected\n'
                      '• On Android: Languages are saved only when model is downloaded\n'
                      '• Recently used languages appear at the top of the list\n'
                      '• Maximum 10 recent languages are stored',
                      style: TextStyle(fontSize: 14),
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
