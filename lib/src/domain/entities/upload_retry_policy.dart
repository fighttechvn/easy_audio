class UploadRetryPolicy {
  const UploadRetryPolicy({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 2),
  });

  final int maxAttempts;
  final Duration delay;
}
