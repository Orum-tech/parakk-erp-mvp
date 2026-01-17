import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  // Download file from URL and save to device
  Future<File> downloadFile({
    required String url,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Navigate to Downloads folder
        if (directory != null) {
          final downloadsPath = '${directory.path}/../Download';
          directory = Directory(downloadsPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop platforms, use application documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access download directory');
      }

      // Download file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Save file
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Download multiple files
  Future<List<File>> downloadFiles({
    required List<String> urls,
    required List<String> fileNames,
    Function(int current, int total, double progress)? onProgress,
  }) async {
    try {
      final downloadedFiles = <File>[];

      for (int i = 0; i < urls.length; i++) {
        final url = urls[i];
        final fileName = fileNames[i];

        final file = await downloadFile(
          url: url,
          fileName: fileName,
          onProgress: (progress) {
            if (onProgress != null) {
              final overallProgress = (i + progress) / urls.length;
              onProgress(i + 1, urls.length, overallProgress);
            }
          },
        );

        downloadedFiles.add(file);
      }

      return downloadedFiles;
    } catch (e) {
      throw Exception('Failed to download files: $e');
    }
  }

  // Get file name from URL
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
