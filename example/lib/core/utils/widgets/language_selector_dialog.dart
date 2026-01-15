import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

/// Dialog hiển thị danh sách ngôn ngữ với ô search
class LanguageSelectorDialog extends StatefulWidget {
  const LanguageSelectorDialog({
    super.key,
    required this.locales,
    required this.selectedLocale,
  });

  final List<SupportedLocale> locales;
  final String? selectedLocale;

  static Future<String?> show({
    required BuildContext context,
    required List<SupportedLocale> locales,
    required String? selectedLocale,
  }) async {
    return showDialog<String?>(
      context: context,
      builder: (context) => LanguageSelectorDialog(
        locales: locales,
        selectedLocale: selectedLocale,
      ),
    );
  }

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<SupportedLocale> _filteredLocales = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredLocales = widget.locales;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredLocales = widget.locales;
      } else {
        _filteredLocales = widget.locales.where((locale) {
          final name = locale.name.toLowerCase();
          final id = locale.localeId.toLowerCase();
          return name.contains(_searchQuery) || id.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chọn ngôn ngữ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ngôn ngữ...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Language list
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        _filteredLocales.length + 1, // +1 for "Auto" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Auto option
                        return _buildLanguageItem(
                          context: context,
                          name: 'Tự động',
                          localeId: null,
                          isSelected: widget.selectedLocale == null,
                          icon: Icons.auto_awesome,
                        );
                      }

                      final locale = _filteredLocales[index - 1];
                      return _buildLanguageItem(
                        context: context,
                        name: locale.name,
                        localeId: locale.localeId,
                        isSelected: widget.selectedLocale == locale.localeId,
                      );
                    },
                  ),
                ),
              ),
            ),

            // Empty state
            if (_filteredLocales.isEmpty && _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy ngôn ngữ "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem({
    required BuildContext context,
    required String name,
    required String? localeId,
    required bool isSelected,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(localeId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isSelected ? Colors.blue : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getLanguageEmoji(localeId ?? ''),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    if (localeId != null)
                      Text(
                        localeId,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageEmoji(String localeId) {
    final languageCode = localeId.split('-').first.toLowerCase();
    final emojiMap = {
      'vi': '🇻🇳',
      'en': '🇺🇸',
      'ja': '🇯🇵',
      'ko': '🇰🇷',
      'zh': '🇨🇳',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'es': '🇪🇸',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'ar': '🇸🇦',
      'th': '🇹🇭',
      'id': '🇮🇩',
      'ms': '🇲🇾',
      'hi': '🇮🇳',
      'bn': '🇧🇩',
      'tr': '🇹🇷',
      'pl': '🇵🇱',
      'nl': '🇳🇱',
      'sv': '🇸🇪',
      'da': '🇩🇰',
      'no': '🇳🇴',
      'fi': '🇫🇮',
      'el': '🇬🇷',
      'he': '🇮🇱',
      'uk': '🇺🇦',
      'cs': '🇨🇿',
      'ro': '🇷🇴',
      'hu': '🇭🇺',
    };
    return emojiMap[languageCode] ?? '🌐';
  }
}
