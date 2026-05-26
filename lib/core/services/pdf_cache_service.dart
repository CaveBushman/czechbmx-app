import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PdfCacheService {
  PdfCacheService._();

  static Future<Directory> _cacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/pdf_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static String _filename(String url) {
    return Uri.parse(url).pathSegments.last.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Returns a cached copy of the PDF file, downloading it if necessary.
  /// [onProgress] receives bytes received and total (may be -1 if unknown).
  static Future<File> ensureCached(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/${_filename(url)}');
    if (file.existsSync()) return file;

    final dio = Dio();
    await dio.download(
      url,
      file.path,
      onReceiveProgress: onProgress,
    );
    return file;
  }

  /// True if a cached copy of the PDF exists locally.
  static Future<bool> isCached(String url) async {
    final dir = await _cacheDir();
    return File('${dir.path}/${_filename(url)}').existsSync();
  }

  /// Open the PDF — downloads first if not yet cached.
  /// Shows [onDownloading] callback during download so the caller can update UI.
  static Future<void> openPdf(
    String url, {
    void Function()? onDownloading,
    void Function()? onDone,
    void Function(Object error)? onError,
  }) async {
    try {
      onDownloading?.call();
      final file = await ensureCached(url);
      onDone?.call();
      await OpenFile.open(file.path);
    } catch (e) {
      onError?.call(e);
    }
  }

  /// Wipe the entire PDF cache (call from settings if needed).
  static Future<void> clearAll() async {
    final dir = await _cacheDir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
