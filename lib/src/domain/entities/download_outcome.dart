enum DownloadStatus { success, cancelled, failure }

class DownloadOutcome {
  const DownloadOutcome._(this.status, [this.error]);

  const DownloadOutcome.success() : this._(DownloadStatus.success);
  const DownloadOutcome.cancelled() : this._(DownloadStatus.cancelled);
  const DownloadOutcome.failure(Object? error)
      : this._(DownloadStatus.failure, error);

  final DownloadStatus status;
  final Object? error;

  String? get errorMessage => error?.toString();
}
