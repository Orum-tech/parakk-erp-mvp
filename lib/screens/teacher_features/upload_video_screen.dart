import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/video_service.dart';
import '../../services/marks_service.dart';
import '../../services/storage_service.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final VideoService _videoService = VideoService();
  final MarksService _marksService = MarksService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _thumbnailUrlController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _selectedSubject;
  final List<String> _selectedClasses = [];
  List<Map<String, String>> _availableSubjects = [];
  List<Map<String, String>> _availableClasses = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _targetAllClasses = true;
  bool _isUploadingVideo = false;
  bool _isUploadingThumbnail = false;
  double _videoUploadProgress = 0.0;
  double _thumbnailUploadProgress = 0.0;
  File? _selectedVideoFile;
  File? _selectedThumbnailFile;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _thumbnailUrlController.dispose();
    _chapterController.dispose();
    _topicController.dispose();
    _durationController.dispose();
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

      final subjects = await _marksService.getTeacherSubjects(user.uid);
      final classes = await _marksService.getTeacherClasses(user.uid);

      setState(() {
        _availableSubjects = subjects;
        _availableClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      setState(() {
        _selectedVideoFile = file;
        _isUploadingVideo = true;
        _videoUploadProgress = 0.0;
      });

      // Upload video to Firebase Storage
      final videoUrl = await _storageService.uploadVideoFile(
        file,
        onProgress: (progress) {
          setState(() => _videoUploadProgress = progress);
        },
      );

      setState(() {
        _videoUrlController.text = videoUrl;
        _isUploadingVideo = false;
        _videoUploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingVideo = false;
        _videoUploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectThumbnailImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) return;

      final file = File(image.path);
      setState(() {
        _selectedThumbnailFile = file;
        _isUploadingThumbnail = true;
        _thumbnailUploadProgress = 0.0;
      });

      // Upload thumbnail to Firebase Storage
      final thumbnailUrl = await _storageService.uploadVideoThumbnail(
        file,
        onProgress: (progress) {
          setState(() => _thumbnailUploadProgress = progress);
        },
      );

      setState(() {
        _thumbnailUrlController.text = thumbnailUrl;
        _isUploadingThumbnail = false;
        _thumbnailUploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thumbnail uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingThumbnail = false;
        _thumbnailUploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading thumbnail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_targetAllClasses && _selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class or select "All Classes"'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate that either video file is uploaded or video URL is provided
    if (_selectedVideoFile == null && _videoUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a video file or provide a video URL'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final duration = int.tryParse(_durationController.text) ?? 0;
      if (duration <= 0) {
        throw Exception('Please enter a valid duration in seconds');
      }

      final targetAudience = _targetAllClasses 
          ? ['all'] 
          : _selectedClasses.map((c) => c).toList();

      await _videoService.createOrUpdateVideo(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
        thumbnailUrl: _thumbnailUrlController.text.trim().isEmpty 
            ? null 
            : _thumbnailUrlController.text.trim(),
        subject: _selectedSubject!,
        chapter: _chapterController.text.trim().isEmpty 
            ? null 
            : _chapterController.text.trim(),
        topic: _topicController.text.trim().isEmpty 
            ? null 
            : _topicController.text.trim(),
        targetAudience: targetAudience,
        duration: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Upload Video", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Upload Video", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Video Title *',
              hint: 'Enter video title',
              icon: Icons.title,
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description *',
              hint: 'Enter video description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 15),
            // Video Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video File *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploadingVideo ? null : _selectVideoFile,
                          icon: _isUploadingVideo
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: _videoUploadProgress,
                                  ),
                                )
                              : const Icon(Icons.video_library),
                          label: Text(
                            _selectedVideoFile != null
                                ? _selectedVideoFile!.path.split('/').last
                                : _isUploadingVideo
                                    ? 'Uploading... ${(_videoUploadProgress * 100).toStringAsFixed(0)}%'
                                    : 'Select Video File',
                          ),
                        ),
                      ),
                      if (_selectedVideoFile != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedVideoFile = null;
                              _videoUrlController.clear();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'OR',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _videoUrlController,
                    label: 'Video URL (Alternative)',
                    hint: 'Enter video URL (YouTube, Vimeo, etc.)',
                    icon: Icons.link,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Thumbnail Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thumbnail Image (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploadingThumbnail ? null : _selectThumbnailImage,
                          icon: _isUploadingThumbnail
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: _thumbnailUploadProgress,
                                  ),
                                )
                              : const Icon(Icons.image),
                          label: Text(
                            _selectedThumbnailFile != null
                                ? _selectedThumbnailFile!.path.split('/').last
                                : _isUploadingThumbnail
                                    ? 'Uploading... ${(_thumbnailUploadProgress * 100).toStringAsFixed(0)}%'
                                    : 'Select Thumbnail',
                          ),
                        ),
                      ),
                      if (_selectedThumbnailFile != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedThumbnailFile = null;
                              _thumbnailUrlController.clear();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'OR',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _thumbnailUrlController,
                    label: 'Thumbnail URL (Alternative)',
                    hint: 'Enter thumbnail image URL',
                    icon: Icons.link,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 15),
            _buildDropdown(
              label: 'Subject *',
              value: _selectedSubject,
              items: _availableSubjects.map((s) => s['name']!).toList(),
              onChanged: (value) => setState(() => _selectedSubject = value),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _chapterController,
              label: 'Chapter (Optional)',
              hint: 'Enter chapter name',
              icon: Icons.menu_book,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _topicController,
              label: 'Topic (Optional)',
              hint: 'Enter topic name',
              icon: Icons.topic,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _durationController,
              label: 'Duration (seconds) *',
              hint: 'Enter duration in seconds',
              icon: Icons.timer,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Duration is required';
                final duration = int.tryParse(value!);
                if (duration == null || duration <= 0) return 'Enter a valid duration';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTargetAudienceSection(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Upload Video',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.subject),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTargetAudienceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Audience',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text('All Classes'),
            value: _targetAllClasses,
            onChanged: (value) {
              setState(() {
                _targetAllClasses = value ?? true;
                if (_targetAllClasses) {
                  _selectedClasses.clear();
                }
              });
            },
          ),
          if (!_targetAllClasses) ...[
            const SizedBox(height: 10),
            ..._availableClasses.map((classData) {
              final classId = classData['id']!;
              final className = classData['name']!;
              return CheckboxListTile(
                title: Text(className),
                value: _selectedClasses.contains(classId),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedClasses.add(classId);
                    } else {
                      _selectedClasses.remove(classId);
                    }
                  });
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}
