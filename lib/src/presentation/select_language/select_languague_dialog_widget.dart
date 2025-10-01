import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

import '../../core/easy_debounce.dart';
import '../../core/widgets/group_check_box_widget.dart';
import '../../easy_audio_constants.dart';

class SelectLanguagueDialogWidget extends StatefulWidget {
  const SelectLanguagueDialogWidget({
    super.key,
    this.langDefault = RecordLanguageContants.defaultLang,
    this.languages = RecordLanguageContants.languages,
  });

  final String langDefault;
  final Map<String, String> languages;

  @override
  State<SelectLanguagueDialogWidget> createState() =>
      _SelectLanguagueDialogWidgetState();
}

class _SelectLanguagueDialogWidgetState
    extends State<SelectLanguagueDialogWidget> {
  late final ModelLoader _modelLoader = ModelLoader();
  late final String? _previousLocale = widget.languages[widget.langDefault];
  late String _languageSelected = widget.langDefault;
  bool _isProcessing = false;
  final _tagDebound = '_select_lang';
  late List<String> _currentList = widget.languages.keys.toList();

  bool get _isAndroidTarget =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    EasyDebounce.cancel(_tagDebound);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            onChanged: (value) {
              EasyDebounce.debounce(
                _tagDebound,
                const Duration(milliseconds: 400),
                () {
                  if (value.isEmpty) {
                    _currentList = widget.languages.keys.toList();
                    setState(() {});
                  } else {
                    _currentList = widget.languages.entries
                        .where((e) =>
                            e.key.toLowerCase().contains(value.toLowerCase()) ||
                            e.value.toLowerCase().contains(value.toLowerCase()))
                        .toList()
                        .map((e) => e.key)
                        .toList();
                    setState(() {});
                  }
                },
              );
            },
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: SingleChildScrollView(
              child: GroupCheckBoxWidget<String>(
                values: _currentList,
                defaultValue: _languageSelected,
                onSelected: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _languageSelected = value;
                  });
                },
                isRadioType: true,
                direction: Axis.vertical,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleConfirm,
            child: _isProcessing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final selectedLabel = _languageSelected;
    final selectedLocale = widget.languages[selectedLabel];

    if (selectedLocale == null || selectedLocale.isEmpty) {
      Navigator.of(context).pop(selectedLocale);
      return;
    }

    if (!_isAndroidTarget) {
      Navigator.of(context).pop(selectedLocale);
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
        Navigator.of(context).pop(selectedLocale);
        return;
      }

      final shouldDownload = await _showDownloadConfirmation(selectedLabel);
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
        case _DownloadStatus.success:
          final confirmed = await _showDownloadSuccess(selectedLabel);
          if (confirmed == true) {
            Navigator.of(context).pop(selectedLocale);
          } else {
            setState(() {
              _languageSelected = widget.langDefault;
            });
          }
          break;
        case _DownloadStatus.cancelled:
          setState(() {
            _languageSelected = widget.langDefault;
          });
          break;
        case _DownloadStatus.failure:
          await _showDownloadError(outcome.errorMessage);
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
    final url = SpeechToTextLocales.voskModelUrlFor(locale);
    if (url == null || url.isEmpty) {
      return false;
    }

    final fileName = _fileNameFromUrl(url);
    final modelName = _modelNameFromFileName(fileName);
    return _modelLoader.isModelAlreadyLoaded(modelName);
  }

  Future<bool> _showDownloadConfirmation(String label) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tải mô hình ngôn ngữ'),
            content: Text(
              'Thiết bị chưa có mô hình cho "$label".'
              '\nBạn có muốn tải về ngay?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Không'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Tải xuống'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<_DownloadOutcome> _downloadModel(
    String locale,
    String label,
  ) async {
    final url = SpeechToTextLocales.voskModelUrlFor(locale);
    if (url == null || url.isEmpty) {
      return const _DownloadOutcome.failure(
          'Không tìm thấy đường dẫn tải mô hình.');
    }

    final progressNotifier = ValueNotifier<double?>(0);
    var isCancelled = false;
    BuildContext? dialogContext;

    void safePop(_DownloadOutcome outcome) {
      final contextToClose = dialogContext;
      if (contextToClose != null) {
        dialogContext = null;
        Navigator.of(contextToClose).pop(outcome);
      }
    }

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
          safePop(const _DownloadOutcome.cancelled());
        } else {
          progressNotifier.value = 1.0;
          safePop(const _DownloadOutcome.success());
        }
      } on ModelDownloadCancelledException {
        safePop(const _DownloadOutcome.cancelled());
      } catch (error, stackTrace) {
        debugPrint('Tải mô hình cho $locale thất bại: $error');
        debugPrintStack(stackTrace: stackTrace);
        safePop(_DownloadOutcome.failure(error));
      }
    }));

    try {
      return await showDialog<_DownloadOutcome>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              dialogContext = ctx;
              return _DownloadProgressDialog(
                languageLabel: label,
                progressListenable: progressNotifier,
                onCancel: () {
                  if (!isCancelled) {
                    isCancelled = true;
                    safePop(const _DownloadOutcome.cancelled());
                  }
                },
              );
            },
          ) ??
          const _DownloadOutcome.cancelled();
    } finally {
      progressNotifier.dispose();
    }
  }

  Future<bool> _showDownloadSuccess(String label) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tải xuống thành công'),
            content: Text('Mô hình cho "$label" đã sẵn sàng. Sử dụng ngay?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Để sau'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _showDownloadError(String? message) {
    final displayMessage = message?.isNotEmpty == true
        ? message!
        : 'Không thể tải mô hình. Vui lòng thử lại sau.';
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lỗi tải mô hình'),
        content: Text(displayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : url;
  }

  String _modelNameFromFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.zip')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }
}

enum _DownloadStatus { success, cancelled, failure }

class _DownloadOutcome {
  const _DownloadOutcome._(this.status, [this.error]);

  const _DownloadOutcome.success() : this._(_DownloadStatus.success);
  const _DownloadOutcome.cancelled() : this._(_DownloadStatus.cancelled);
  const _DownloadOutcome.failure(Object? error)
      : this._(_DownloadStatus.failure, error);

  final _DownloadStatus status;
  final Object? error;

  String? get errorMessage => error?.toString();
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog({
    required this.languageLabel,
    required this.progressListenable,
    required this.onCancel,
  });

  final String languageLabel;
  final ValueListenable<double?> progressListenable;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đang tải mô hình'),
      content: ValueListenableBuilder<double?>(
        valueListenable: progressListenable,
        builder: (context, progress, _) {
          final hasProgress = progress != null;
          final double? progressValue;
          if (hasProgress) {
            final value = progress;
            progressValue =
                value < 0 ? 0.0 : (value > 1 ? 1.0 : value.toDouble());
          } else {
            progressValue = null;
          }
          final percentLabel = hasProgress
              ? () {
                  final percent = progressValue! * 100;
                  final safePercent =
                      percent < 0 ? 0 : (percent > 100 ? 100 : percent);
                  return '${safePercent.toStringAsFixed(0)}%';
                }()
              : 'Đang tải...';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mô hình "$languageLabel" đang được tải xuống.'),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 8),
              Text('Tiến trình: $percentLabel'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
