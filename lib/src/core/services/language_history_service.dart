import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Service to manage language usage history
class LanguageHistoryService {
  static const String _keyUsedLanguages = 'easy_audio_used_languages';
  static const String _keyDownloadedModels = 'easy_audio_downloaded_models';

  /// Get list of recently used languages sorted by most recent first
  static Future<List<String>> getRecentlyUsedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUsedLanguages);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => item['locale'] as String).toList();
    } catch (e) {
      debugPrint('Error parsing used languages: $e');
      return [];
    }
  }

  /// Add a language to the usage history
  /// For Android: only add if model is downloaded
  /// For iOS: add when language is selected
  static Future<void> addUsedLanguage(String locale) async {
    final prefs = await SharedPreferences.getInstance();

    // Check platform-specific conditions
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // For Android, only add if model is downloaded
      final isModelDownloaded = await _isModelDownloaded(locale);
      if (!isModelDownloaded) {
        return;
      }
    }

    final currentList = await getRecentlyUsedLanguages();

    // Remove if already exists to avoid duplicates
    currentList.remove(locale);

    // Add to the beginning (most recent)
    currentList.insert(0, locale);

    // Keep only last 10 languages to avoid too much storage
    if (currentList.length > 10) {
      currentList.removeRange(10, currentList.length);
    }

    // Convert to JSON format with timestamp
    final jsonList = currentList
        .map((lang) => {
              'locale': lang,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            })
        .toList();

    final jsonString = json.encode(jsonList);
    await prefs.setString(_keyUsedLanguages, jsonString);
  }

  /// Mark a model as downloaded (Android only)
  static Future<void> markModelAsDownloaded(String locale) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final downloadedModels = await _getDownloadedModels();

    if (!downloadedModels.contains(locale)) {
      downloadedModels.add(locale);
      await prefs.setStringList(_keyDownloadedModels, downloadedModels);
    }

    // Also add to used languages when model is downloaded
    await addUsedLanguage(locale);
  }

  /// Check if a model is downloaded (Android only)
  static Future<bool> _isModelDownloaded(String locale) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true; // For non-Android platforms, consider as always available
    }

    try {
      // Check using ModelLoader
      final modelLoader = ModelLoader();
      final url = RecordLanguage.voskModelUrlFor(locale);
      if (url == null || url.isEmpty) {
        return false;
      }

      final fileName = _fileNameFromUrl(url);
      final modelName = _modelNameFromFileName(fileName);
      return modelLoader.isModelAlreadyLoaded(modelName);
    } catch (e) {
      debugPrint('Error checking model download status: $e');
      return false;
    }
  }

  /// Get list of downloaded models (Android only)
  static Future<List<String>> _getDownloadedModels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyDownloadedModels) ?? [];
  }

  /// Sort languages by putting recently used ones first
  static Future<List<String>> sortLanguagesByUsage(
    List<String> allLanguages,
  ) async {
    final recentlyUsed = await getRecentlyUsedLanguages();
    final sortedList = <String>[];

    // 1. Add 'en' first if it exists in allLanguages
    if (allLanguages.contains('en')) {
      sortedList.add('en');
    }

    // 2. Add recently used languages (excluding 'en' if already added)
    for (final usedLang in recentlyUsed) {
      if (allLanguages.contains(usedLang) && !sortedList.contains(usedLang)) {
        sortedList.add(usedLang);
      }
    }

    // 3. Add remaining languages that haven't been used
    for (final lang in allLanguages) {
      if (!sortedList.contains(lang)) {
        sortedList.add(lang);
      }
    }

    return sortedList;
  }

  /// Clear all language history (for testing or reset purposes)
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsedLanguages);
    await prefs.remove(_keyDownloadedModels);
  }

  // Helper methods
  static String _fileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : url;
  }

  static String _modelNameFromFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.zip')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }
}
