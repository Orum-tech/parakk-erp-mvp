import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../../services/download_service.dart';

class SavedResourcesScreen extends StatefulWidget {
  const SavedResourcesScreen({super.key});

  @override
  State<SavedResourcesScreen> createState() => _SavedResourcesScreenState();
}

class _SavedResourcesScreenState extends State<SavedResourcesScreen> {
  final DownloadService _downloadService = DownloadService();
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    setState(() => _isLoading = true);
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final downloadsPath = '${extDir.path}/../Download';
          directory = Directory(downloadsPath);
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop platforms, use application documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (await directory.exists()) {
        final files = directory.listSync()
            .whereType<File>()
            .cast<File>()
            .toList();
        
        // Sort by modification date (newest first)
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.modified.compareTo(aStat.modified);
        });

        setState(() {
          _downloadedFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Downloads", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloadedFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No downloaded files',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Files you download will appear here',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDownloadedFiles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _downloadedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _downloadedFiles[index] as File;
                      final fileName = file.path.split('/').last;
                      final fileSize = file.lengthSync();
                      final sizeStr = _downloadService.formatFileSize(fileSize);
                      final icon = _getFileIcon(fileName);
                      final color = _getFileColor(fileName);

                      return _buildFileCard(file, fileName, sizeStr, icon, color);
                    },
                  ),
                ),
    );
  }

  Widget _buildFileCard(File file, String name, String size, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(size),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.open_in_new, size: 20),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
              onTap: () => _openFile(file),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
              onTap: () => _shareFile(file),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _deleteFile(file),
            ),
          ],
        ),
        onTap: () => _openFile(file),
      ),
    );
  }

  Future<void> _openFile(File file) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.path.split('/').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await file.delete();
        _loadDownloadedFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}