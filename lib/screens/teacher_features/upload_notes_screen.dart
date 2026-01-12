import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/notes_service.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  final NotesService _notesService = NotesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Selection state
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  // Data lists
  List<Map<String, String>> _classes = [];
  List<Map<String, String>> _subjects = [];

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();

  // File state
  List<File> _selectedFiles = []; // Actual file objects
  List<String> _selectedFileNames = []; // File names for display
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final classes = await _notesService.getTeacherClasses(user.uid);
      final subjects = await _notesService.getTeacherSubjects(user.uid);

      setState(() {
        _classes = classes;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectFiles() async {
    if (!mounted) return;
    
    // Use post-frame callback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      try {
        // Initialize file picker platform by clearing temp files
        try {
          FilePicker.platform.clearTemporaryFiles();
        } catch (e) {
          // Ignore errors from clearTemporaryFiles
        }
        
        // Wait for platform to be ready
        await Future.delayed(const Duration(milliseconds: 500));

        FilePickerResult? result;
        
        // Try to pick files with multiple retry attempts
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount < maxRetries && mounted) {
          try {
            result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
              allowMultiple: true,
              withData: false,
              withReadStream: false,
            );
            break; // Success, exit retry loop
          } catch (pickerError) {
            retryCount++;
            final errorStr = pickerError.toString();
            
            if (errorStr.contains('LateInitializationError') && retryCount < maxRetries) {
              // Try to initialize again
              try {
                FilePicker.platform.clearTemporaryFiles();
              } catch (e) {
                // Ignore
              }
              // Exponential backoff
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
              continue; // Retry
            } else {
              // If it's not a LateInitializationError or we've exhausted retries, throw
              if (!mounted) return;
              rethrow;
            }
          }
        }

        if (result == null) {
          // User cancelled or no files selected
          return;
        }

        if (result.files.isNotEmpty) {
        final files = <File>[];
        final fileNames = <String>[];

        for (var platformFile in result.files) {
          if (platformFile.path != null) {
            try {
              final file = File(platformFile.path!);
              // Verify file exists and is readable
              if (await file.exists()) {
                files.add(file);
                fileNames.add(platformFile.name);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File ${platformFile.name} does not exist'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error accessing file ${platformFile.name}: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else if (platformFile.bytes != null) {
            // Handle web platform where path might be null but bytes are available
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Web file upload not yet supported. Please use mobile app.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

          if (files.isNotEmpty && mounted) {
            setState(() {
              _selectedFiles = files;
              _selectedFileNames = fileNames;
            });
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No valid files were selected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
        String errorMessage = 'Error selecting files';
        String? detailedError;
        
        if (e.toString().contains('LateInitializationError')) {
          errorMessage = 'File picker initialization error';
          detailedError = 'Please restart the app and try again. If the problem persists, this may be a platform-specific issue.';
        } else if (e.toString().contains('Permission')) {
          errorMessage = 'Storage permission required';
          detailedError = 'Please grant storage permission in app settings.';
        } else {
          errorMessage = 'Error selecting files';
          detailedError = e.toString();
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(errorMessage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detailedError != null) Text(detailedError),
                const SizedBox(height: 16),
                const Text(
                  'You can try:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Restart the app'),
                const Text('2. Check app permissions'),
                const Text('3. Try again after a few seconds'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Retry after a longer delay
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) _selectFiles();
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        }
        print('File picker error: $e'); // Debug print
      }
    });
  }

  Future<void> _handleUpload() async {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class and subject'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload files to Firebase Storage
      final fileUrls = await _notesService.uploadFiles(
        files: _selectedFiles,
        userId: user.uid,
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        onProgress: (current, total, progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      // Calculate total file size
      int totalFileSize = 0;
      for (var file in _selectedFiles) {
        totalFileSize += await _notesService.getFileSize(file);
      }

      // Determine file type from first file
      final firstFileName = _selectedFileNames.first;
      final fileType = _getFileType(firstFileName);

      // Save note to Firestore
      await _notesService.uploadTeacherNote(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        classId: _selectedClassId!,
        className: _selectedClassName!,
        subjectId: _selectedSubjectId!,
        subjectName: _selectedSubjectName!,
        chapterName: _chapterController.text.trim().isEmpty
            ? null
            : _chapterController.text.trim(),
        attachmentUrls: fileUrls,
        fileType: fileType,
        fileSize: totalFileSize,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes Uploaded Successfully! 📤'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _chapterController.clear();
        setState(() {
          _selectedFiles = [];
          _selectedFileNames = [];
          _uploadProgress = 0.0;
          _selectedClassId = null;
          _selectedSubjectId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'docx';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image';
      default:
        return 'other';
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
        return Icons.image;
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
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Upload Materials", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Upload Materials", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Selection
            DropdownButtonFormField<String>(
              value: _selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Select Class *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _classes.map((cls) {
                return DropdownMenuItem(
                  value: cls['id'],
                  child: Text(cls['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  _selectedClassName = _classes.firstWhere((c) => c['id'] == value)['name'];
                });
              },
            ),
            const SizedBox(height: 20),

            // Subject Selection
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(
                labelText: 'Select Subject *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _subjects.map((subj) {
                return DropdownMenuItem(
                  value: subj['id'],
                  child: Text(subj['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubjectId = value;
                  _selectedSubjectName = _subjects.firstWhere((s) => s['id'] == value)['name'];
                });
              },
            ),
            const SizedBox(height: 20),

            // Upload Area
            GestureDetector(
              onTap: _selectFiles,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFiles.isEmpty ? Icons.cloud_upload_rounded : Icons.check_circle,
                      size: 50,
                      color: _selectedFiles.isEmpty ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedFiles.isEmpty
                          ? "Tap to browse files"
                          : "${_selectedFiles.length} file(s) selected",
                      style: TextStyle(
                        color: _selectedFiles.isEmpty ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                    const Text(
                      "PDF, DOCX, JPG supported",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedFileNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._selectedFileNames.asMap().entries.map((entry) {
                final index = entry.key;
                final fileName = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(fileName),
                        color: _getFileColor(fileName),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_isUploading)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                              _selectedFileNames.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 30),

            // Form Fields
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title / Topic Name *',
                prefixIcon: const Icon(Icons.title, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _chapterController,
              decoration: InputDecoration(
                labelText: 'Chapter Name (Optional)',
                prefixIcon: const Icon(Icons.menu_book, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: const Icon(Icons.description, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "UPLOAD NOW",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
