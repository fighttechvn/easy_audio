import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

import '../../core/easy_debounce.dart';
import '../../core/services/language_history_service.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/download_outcome.dart';
import '../shared/app_dialog.dart';
import 'widgets/confirm_button.dart';
import 'widgets/language_list_view.dart';
import 'widgets/language_search_bar.dart';

class SelectLanguagueDialogWidget extends StatefulWidget {
  const SelectLanguagueDialogWidget({
    super.key,
    this.langDefault = RecordLanguage.defaultLocale,
    this.languages,
  });

  final String langDefault;
  final Map<String, String>? languages;

  @override
  State<SelectLanguagueDialogWidget> createState() =>
      _SelectLanguagueDialogWidgetState();
}

class _SelectLanguagueDialogWidgetState
    extends State<SelectLanguagueDialogWidget> {
  late final ModelLoader _modelLoader = ModelLoader();
  Map<String, String> _languages = const <String, String>{};
  String? _previousLocale;
  late String _languageSelected = widget.langDefault;
  bool _isProcessing = false;
  final _tagDebound = '_select_lang';
  List<String> _currentList = const <String>[];
  List<String> _sortedLanguageKeys = const <String>[];
  bool _isLoadingLanguages = false;

  bool get _isAndroidTarget =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _initialiseLanguages();
  }

  @override
  void dispose() {
    EasyDebounce.cancel(_tagDebound);

    super.dispose();
  }

  Future<void> _initialiseLanguages() async {
    _applyLanguages(widget.languages ?? RecordLanguage.supported);

    if (widget.languages != null) {
      return;
    }

    setState(() {
      _isLoadingLanguages = true;
    });

    try {
      final updated = await RecordLanguage.ensureSystemLocalesLoaded();
      if (!mounted) {
        return;
      }
      if (!mapEquals(updated, _languages)) {
        _applyLanguages(updated);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLanguages = false;
        });
      }
    }
  }

  void _applyLanguages(Map<String, String> languages) {
    _languages = Map<String, String>.from(languages);
    _previousLocale = _languages[widget.langDefault];
    if (!_languages.containsKey(_languageSelected)) {
      _languageSelected = widget.langDefault;
    }
    _currentList = _languages.keys.toList();
    _sortedLanguageKeys = _currentList;
    _loadSortedLanguages();
  }

  Future<void> _loadSortedLanguages() async {
    try {
      final sortedKeys = await LanguageHistoryService.sortLanguagesByUsage(
        _languages.keys.toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _sortedLanguageKeys = sortedKeys;
        _currentList = sortedKeys;
      });
    } catch (e) {
      debugPrint('Error loading sorted languages: $e');
      // Fallback to original order if there's an error
      if (!mounted) {
        return;
      }
      setState(() {
        _sortedLanguageKeys = _languages.keys.toList();
        _currentList = _sortedLanguageKeys;
      });
    }
  }

  Future<void> _handleConfirm() async {
    final selectedLabel = _languageSelected;
    final selectedLocale = _languages[selectedLabel];

    if (selectedLocale == null || selectedLocale.isEmpty) {
      Navigator.of(context).pop(selectedLocale);
      return;
    }

    if (!_isAndroidTarget) {
      // For iOS, save the language as used when selected
      await LanguageHistoryService.addUsedLanguage(selectedLabel);
      if (mounted) {
        Navigator.of(context).pop(selectedLocale);
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (selectedLocale == _previousLocale) {
        Navigator.of(context).pop(selectedLocale);
        return;
      }

      final modelReady = await _isModelReady(selectedLocale);
      if (modelReady) {
        // Model is already available, add to used languages
        await LanguageHistoryService.addUsedLanguage(selectedLabel);
        if (mounted) {
          Navigator.of(context).pop(selectedLocale);
        }
        return;
      }

      if (!mounted) {
        return;
      }

      final shouldDownload = await context.showDownloadConfirm(selectedLabel);
      if (!shouldDownload) {
        if (!mounted) {
          return;
        }
        setState(() {
          _languageSelected = widget.langDefault;
        });
        return;
      }

      final outcome = await _downloadModel(selectedLocale, selectedLabel);
      if (!mounted) {
        return;
      }

      switch (outcome.status) {
        case DownloadStatus.success:
          // Mark model as downloaded and add to used languages
          await LanguageHistoryService.markModelAsDownloaded(selectedLabel);
          if (!mounted) {
            return;
          }
          final confirmed = await context.showDownloadSuccess(selectedLabel);
          if (confirmed == true) {
            if (mounted) {
              Navigator.of(context).pop(selectedLocale);
            }
          } else {
            if (mounted) {
              setState(() {
                _languageSelected = widget.langDefault;
              });
            }
          }
          break;
        case DownloadStatus.cancelled:
          setState(() {
            _languageSelected = widget.langDefault;
          });
          break;
        case DownloadStatus.failure:
          await context.showDownloadError(outcome.errorMessage);
          if (!mounted) {
            return;
          }
          setState(() {
            _languageSelected = widget.langDefault;
          });
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _isModelReady(String locale) async {
    final url = RecordLanguage.voskModelUrlFor(locale);
    if (url == null || url.isEmpty) {
      return false;
    }

    final fileName = FileUtils.fileNameFromUrl(url);
    final modelName = FileUtils.modelNameFromFileName(fileName);
    return _modelLoader.isModelAlreadyLoaded(modelName);
  }

  Future<DownloadOutcome> _downloadModel(
    String locale,
    String label,
  ) async {
    final url = RecordLanguage.voskModelUrlFor(locale);
    if (url == null || url.isEmpty) {
      return const DownloadOutcome.failure(
          'Không tìm thấy đường dẫn tải mô hình.');
    }

    final progressNotifier = ValueNotifier<double?>(0);
    var isCancelled = false;
    BuildContext? dialogContext;

    void safePop(DownloadOutcome outcome) {
      final contextToClose = dialogContext;
      if (contextToClose != null) {
        dialogContext = null;
        Navigator.of(contextToClose).pop(outcome);
      }
    }

    debugPrint('Download model: $url');

    unawaited(Future<void>(() async {
      try {
        await _modelLoader.loadFromNetworkWithProgress(
          url,
          onProgress: (received, total) {
            if (total == null || total <= 0) {
              progressNotifier.value = null;
              return;
            }
            final progress = received / total;
            final normalized =
                progress < 0 ? 0.0 : (progress > 1 ? 1.0 : progress.toDouble());
            progressNotifier.value = normalized;
          },
          isCancelled: () => isCancelled,
        );
        if (isCancelled) {
          safePop(const DownloadOutcome.cancelled());
        } else {
          progressNotifier.value = 1.0;
          safePop(const DownloadOutcome.success());
        }
      } on ModelDownloadCancelledException {
        safePop(const DownloadOutcome.cancelled());
      } catch (error, stackTrace) {
        debugPrint('Tải mô hình cho $locale thất bại: $error');
        debugPrintStack(stackTrace: stackTrace);
        safePop(DownloadOutcome.failure(error));
      }
    }));

    try {
      return await context.showDownloadProgessDialog(
            label: label,
            progressListenable: progressNotifier,
            updateContext: (ctx) {
              dialogContext = ctx;
            },
            onCancel: () {
              if (!isCancelled) {
                isCancelled = true;
                safePop(const DownloadOutcome.cancelled());
              }
            },
          ) ??
          const DownloadOutcome.cancelled();
    } finally {
      progressNotifier.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LanguageSearchBar(
            debounceTag: _tagDebound,
            onChanged: (value) {
              if (value.isEmpty) {
                _currentList = _sortedLanguageKeys;
                setState(() {});
              } else {
                // Filter from sorted list to maintain order
                _currentList = _sortedLanguageKeys.where((key) {
                  final languageValue = _languages[key] ?? '';
                  return key.toLowerCase().contains(value.toLowerCase()) ||
                      languageValue.toLowerCase().contains(value.toLowerCase());
                }).toList();
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 26),
          LanguageListView(
            currentList: _currentList,
            languageSelected: _languageSelected,
            onSelected: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _languageSelected = value;
              });
            },
          ),
          if (_isLoadingLanguages)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          ConfirmButton(
            isProcessing: _isProcessing,
            onPressed: _isProcessing ? null : _handleConfirm,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
