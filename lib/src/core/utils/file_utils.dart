class FileUtils {
  static String fileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : url;
  }

  static String modelNameFromFileName(String fileName) {
    if (fileName.toLowerCase().endsWith('.zip')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }
}
