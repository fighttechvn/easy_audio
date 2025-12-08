import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

/// Language picker dialog widget
class LanguagePickerDialog extends StatefulWidget {
  const LanguagePickerDialog({
    super.key,
    required this.currentLocale,
    this.preloadedLanguages,
  });

  final String currentLocale;
  final Map<String, String>? preloadedLanguages;

  @override
  State<LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<LanguagePickerDialog> {
  String _searchQuery = '';
  Map<String, String> _allLanguages = {};
  List<MapEntry<String, String>> _filteredLanguages = [];

  // Popular languages for quick access
  static const _popularLanguages = [
    'English (United States)',
    'Vietnamese (Vietnam)',
    'Chinese (China mainland)',
    'Japanese (Japan)',
    'Korean (South Korea)',
    'Spanish (Spain)',
    'French (France)',
    'German (Germany)',
  ];

  @override
  void initState() {
    super.initState();
    _initLanguages();
  }

  Future<void> _initLanguages() async {
    if (widget.preloadedLanguages != null) {
      // Use preloaded languages
      _allLanguages = widget.preloadedLanguages!;
    } else {
      // Load languages if not preloaded
      _allLanguages = await RecordLanguage.ensureSystemLocalesLoaded();
    }
    _filterLanguages();
  }

  void _filterLanguages() {
    if (_searchQuery.isEmpty) {
      _filteredLanguages = _allLanguages.entries.toList();
    } else {
      _filteredLanguages = _allLanguages.entries
          .where((entry) =>
              entry.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              entry.value.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _filteredLanguages.sort((a, b) => a.key.compareTo(b.key));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Language',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search languages...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterLanguages();
                },
              ),
            ),

            // Popular languages (if no search)
            if (_searchQuery.isEmpty) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Popular Languages',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      ..._popularLanguages.map((label) {
                        final entry = _allLanguages.entries.firstWhere(
                          (e) => e.key == label,
                          orElse: () => const MapEntry('', ''),
                        );
                        if (entry.key.isEmpty) return const SizedBox.shrink();

                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.star_outline, size: 20),
                          title: Text(entry.key),
                          subtitle: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: entry.value == widget.currentLocale
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () => Navigator.pop(context, entry),
                        );
                      }),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'All Languages',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      ..._allItems(),
                    ],
                  ),
                ),
              )
            ] else

              // Language list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _allItems(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _allItems() {
    return List.generate(_filteredLanguages.length, (int index) {
      final entry = _filteredLanguages[index];
      return ListTile(
        dense: true,
        title: Text(entry.key),
        subtitle: Text(
          entry.value,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: entry.value == widget.currentLocale
            ? const Icon(Icons.check, color: Colors.green)
            : null,
        onTap: () => Navigator.pop(context, entry),
      );
    });
  }
}
