class EasyAudioLocalizations {
  /// Dialog title for stop recording confirmation.
  final String stopRecordingTitle;

  /// Dialog message for stop recording confirmation.
  final String stopRecordingMessage;

  /// Cancel button text.
  final String cancelButton;

  /// Stop button text.
  final String stopButton;

  /// Save button text.
  final String saveButton;

  /// Message shown when microphone permission is denied.
  final String permissionDeniedMessage;

  /// Message shown when recording fails.
  final String recordingFailedMessage;

  /// Message for recording in progress dialog title.
  final String recordingInProgressTitle;

  /// Message for recording in progress dialog content.
  final String recordingInProgressMessage;

  /// Button text for reopening recording session.
  final String reopenRecordingButton;

  /// Message when file path is empty.
  final String emptyFilePathMessage;

  /// Message when file not found.
  final String fileNotFoundMessage;

  /// Dialog title for selecting language.
  final String selectLanguageTitle;

  const EasyAudioLocalizations({
    this.stopRecordingTitle = 'Stop Recording?',
    this.stopRecordingMessage =
        'Are you sure you want to stop the current recording session?',
    this.cancelButton = 'Cancel',
    this.stopButton = 'Stop',
    this.saveButton = 'Save',
    this.permissionDeniedMessage = 'Microphone permission is required',
    this.recordingFailedMessage = 'Recording failed',
    this.recordingInProgressTitle = 'Recording in Progress',
    this.recordingInProgressMessage =
        'There is currently an active recording session. '
            'You need to end the current recording session before starting'
            ' a new one.',
    this.reopenRecordingButton = 'Reopen Recording Session',
    this.emptyFilePathMessage = 'Recording file path is empty',
    this.fileNotFoundMessage = 'Recording file not found',
    this.selectLanguageTitle = 'Select Language',
  });

  /// Vietnamese localization.
  static const EasyAudioLocalizations vi = EasyAudioLocalizations(
    stopRecordingTitle: 'Dừng ghi âm?',
    stopRecordingMessage:
        'Bạn có chắc muốn dừng phiên ghi âm hiện tại không?',
    cancelButton: 'Hủy',
    stopButton: 'Dừng',
    saveButton: 'Lưu',
    permissionDeniedMessage: 'Cần cấp quyền microphone để ghi âm',
    recordingFailedMessage: 'Ghi âm thất bại',
    recordingInProgressTitle: 'Đang ghi âm',
    recordingInProgressMessage:
        'Hiện đang có phiên ghi âm đang hoạt động. '
            'Bạn cần kết thúc phiên ghi âm hiện tại trước khi bắt đầu phiên mới.',
    reopenRecordingButton: 'Mở lại phiên ghi âm',
    emptyFilePathMessage: 'Đường dẫn file ghi âm trống',
    fileNotFoundMessage: 'Không tìm thấy file ghi âm',
    selectLanguageTitle: 'Chọn ngôn ngữ',
  );

  /// Copy with modified values.
  EasyAudioLocalizations copyWith({
    String? stopRecordingTitle,
    String? stopRecordingMessage,
    String? cancelButton,
    String? stopButton,
    String? saveButton,
    String? permissionDeniedMessage,
    String? recordingFailedMessage,
    String? recordingInProgressTitle,
    String? recordingInProgressMessage,
    String? reopenRecordingButton,
    String? emptyFilePathMessage,
    String? fileNotFoundMessage,
    String? selectLanguageTitle,
  }) {
    return EasyAudioLocalizations(
      stopRecordingTitle: stopRecordingTitle ?? this.stopRecordingTitle,
      stopRecordingMessage: stopRecordingMessage ?? this.stopRecordingMessage,
      cancelButton: cancelButton ?? this.cancelButton,
      stopButton: stopButton ?? this.stopButton,
      saveButton: saveButton ?? this.saveButton,
      permissionDeniedMessage:
          permissionDeniedMessage ?? this.permissionDeniedMessage,
      recordingFailedMessage:
          recordingFailedMessage ?? this.recordingFailedMessage,
      recordingInProgressTitle:
          recordingInProgressTitle ?? this.recordingInProgressTitle,
      recordingInProgressMessage:
          recordingInProgressMessage ?? this.recordingInProgressMessage,
      reopenRecordingButton:
          reopenRecordingButton ?? this.reopenRecordingButton,
      emptyFilePathMessage: emptyFilePathMessage ?? this.emptyFilePathMessage,
      fileNotFoundMessage: fileNotFoundMessage ?? this.fileNotFoundMessage,
      selectLanguageTitle: selectLanguageTitle ?? this.selectLanguageTitle,
    );
  }
}
