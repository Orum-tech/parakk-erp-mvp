import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/notes_service.dart';
import '../../models/note_model.dart';
import '../../models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _notesService = NotesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  int _selectedTab = 0; // 0 = Lecture Notes, 1 = My Notes
  StudentModel? _student;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (studentDoc.exists && mounted) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _uploadMyNote() async {
    if (_student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student data not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final chapterController = TextEditingController();
    String? selectedSubjectId;
    String? selectedSubjectName;
    List<File> selectedFiles = [];
    List<String> selectedFileNames = [];
    bool isUploading = false;
    double uploadProgress = 0.0;

    // Get available subjects (could be from student's class subjects)
    // For now, use a simple list
    final availableSubjects = [
      {'id': 'Mathematics', 'name': 'Mathematics'},
      {'id': 'Physics', 'name': 'Physics'},
      {'id': 'Chemistry', 'name': 'Chemistry'},
      {'id': 'English', 'name': 'English'},
      {'id': 'Biology', 'name': 'Biology'},
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload My Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    border: OutlineInputBorder(),
                  ),
                  items: availableSubjects.map((subj) {
                    return DropdownMenuItem(
                      value: subj['id'],
                      child: Text(subj['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSubjectId = value;
                      selectedSubjectName = availableSubjects
                          .firstWhere((s) => s['id'] == value)['name'];
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: chapterController,
                  decoration: const InputDecoration(
                    labelText: 'Chapter (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // Use post-frame callback to ensure widget is fully built
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
                        
                        while (retryCount < maxRetries) {
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
                              rethrow;
                            }
                          }
                        }

                        if (result != null && result.files.isNotEmpty) {
                          final files = <File>[];
                          final fileNames = <String>[];

                          for (var platformFile in result.files) {
                            if (platformFile.path != null) {
                              try {
                                final file = File(platformFile.path!);
                                if (await file.exists()) {
                                  files.add(file);
                                  fileNames.add(platformFile.name);
                                }
                              } catch (e) {
                                // Skip invalid files
                              }
                            }
                          }

                          if (files.isNotEmpty) {
                            setDialogState(() {
                              selectedFiles = files;
                              selectedFileNames = fileNames;
                            });
                          }
                        }
                      } catch (e) {
                        String errorMessage = 'Error selecting files';
                        if (e.toString().contains('LateInitializationError')) {
                          errorMessage = 'File picker not ready. Please try again.';
                        } else {
                          errorMessage = 'Error: ${e.toString()}';
                        }
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(
                          selectedFiles.isEmpty
                              ? 'Select Files'
                              : '${selectedFiles.length} file(s) selected',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedFileNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...selectedFileNames.map((name) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(name, style: const TextStyle(fontSize: 12)),
                      )),
                ],
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 8),
                  Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (selectedSubjectId == null || titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (selectedFiles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select at least one file'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isUploading = true);

                      try {
                        final user = _auth.currentUser;
                        if (user == null) throw Exception('User not authenticated');

                        // Upload files
                        final fileUrls = await _notesService.uploadFiles(
                          files: selectedFiles,
                          userId: user.uid,
                          classId: _student!.classId ?? '',
                          subjectId: selectedSubjectId!,
                          onProgress: (current, total, progress) {
                            setDialogState(() {
                              uploadProgress = progress;
                            });
                          },
                        );

                        // Calculate file size
                        int totalFileSize = 0;
                        for (var file in selectedFiles) {
                          totalFileSize += await _notesService.getFileSize(file);
                        }

                        // Save note
                        await _notesService.uploadStudentNote(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          subjectId: selectedSubjectId!,
                          subjectName: selectedSubjectName!,
                          chapterName: chapterController.text.trim().isEmpty
                              ? null
                              : chapterController.text.trim(),
                          attachmentUrls: fileUrls,
                          fileType: _getFileType(selectedFileNames.first),
                          fileSize: totalFileSize,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note uploaded successfully! ✅'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
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

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    if (_searchQuery.isEmpty) return notes;
    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery) ||
          note.subjectName.toLowerCase().contains(_searchQuery) ||
          (note.chapterName?.toLowerCase().contains(_searchQuery) ?? false) ||
          (note.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _selectedTab,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Notes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Lecture Notes', icon: Icon(Icons.school, size: 18)),
              Tab(text: 'My Notes', icon: Icon(Icons.person, size: 18)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search chapter or subject...",
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildLectureNotesTab(),
                  _buildMyNotesTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _selectedTab == 1
            ? FloatingActionButton(
                onPressed: _uploadMyNote,
                backgroundColor: const Color(0xFF1565C0),
                child: const Icon(Icons.cloud_upload_rounded),
              )
            : null,
      ),
    );
  }

  Widget _buildLectureNotesTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view notes'));
    }

    return StreamBuilder<List<NoteModel>>(
      stream: _notesService.getLectureNotesForStudent(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allNotes = snapshot.data ?? [];
        final filteredNotes = _filterNotes(allNotes);

        if (filteredNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No notes found matching your search'
                      : 'No lecture notes available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Group by subject
        final notesBySubject = <String, List<NoteModel>>{};
        for (var note in filteredNotes) {
          if (!notesBySubject.containsKey(note.subjectName)) {
            notesBySubject[note.subjectName] = [];
          }
          notesBySubject[note.subjectName]!.add(note);
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...notesBySubject.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15, top: 10),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...entry.value.map((note) => _buildNoteCard(note, isStudentNote: false)),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMyNotesTab() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view notes'));
    }

    return StreamBuilder<List<NoteModel>>(
      stream: _notesService.getStudentNotes(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allNotes = snapshot.data ?? [];
        final filteredNotes = _filterNotes(allNotes);

        if (filteredNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_add_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No notes found matching your search'
                      : 'No notes uploaded yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the + button to upload your notes',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Group by subject
        final notesBySubject = <String, List<NoteModel>>{};
        for (var note in filteredNotes) {
          if (!notesBySubject.containsKey(note.subjectName)) {
            notesBySubject[note.subjectName] = [];
          }
          notesBySubject[note.subjectName]!.add(note);
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...notesBySubject.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15, top: 10),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...entry.value.map((note) => _buildNoteCard(note, isStudentNote: true)),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildNoteCard(NoteModel note, {required bool isStudentNote}) {
    final fileCount = note.attachmentUrls.length;
    final date = note.createdAt.toDate();
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (note.chapterName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chapter: ${note.chapterName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isStudentNote ? Colors.blue[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isStudentNote ? 'My Note' : 'Lecture',
                  style: TextStyle(
                    color: isStudentNote ? Colors.blue[700] : Colors.green[700],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (note.description != null && note.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.insert_drive_file, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                '$fileCount file${fileCount != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 15),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                dateStr,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (!isStudentNote) ...[
                const SizedBox(width: 15),
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  note.teacherName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement download
                  _notesService.incrementDownloadCount(note.noteId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download feature coming soon')),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              if (isStudentNote)
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Note'),
                        content: const Text('Are you sure you want to delete this note?'),
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
                        await _notesService.deleteNote(note.noteId, true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
