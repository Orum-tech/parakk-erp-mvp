import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/homework_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class CreateHomeworkScreen extends StatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeworkService = HomeworkService();
  final _authService = AuthService();
  final _storageService = StorageService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedSubject;
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUploadingFiles = false;
  double _uploadProgress = 0.0;
  List<String> _availableClasses = [];
  final List<String> _availableSections = ['A', 'B', 'C', 'D'];
  List<String> _availableSubjects = [];
  final List<String> _attachmentUrls = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoadingData = true);
    try {
      final user = await _authService.getCurrentUserWithData();
      if (user == null) {
        setState(() => _isLoadingData = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final classIds = List<String>.from(data['classIds'] ?? []);
        final subjects = List<String>.from(data['subjects'] ?? []);

        // Extract unique class numbers from classIds (format: class_5_A)
        final classNumbers = classIds
            .map((id) => id.replaceFirst('class_', '').split('_').first)
            .toSet()
            .toList()
          ..sort();

        setState(() {
          _availableClasses = classNumbers;
          _availableSubjects = subjects;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedSection == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class, section, and subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final classId = 'class_${_selectedClass}_$_selectedSection';
      final className = 'Class $_selectedClass';
      final section = _selectedSection!;

      await _homeworkService.createHomework(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty 
            ? null 
            : _descController.text.trim(),
        classId: classId,
        className: className,
        section: section,
        subjectId: _selectedSubject!,
        subjectName: _selectedSubject!,
        dueDate: _dueDate,
        attachmentUrls: _attachmentUrls.isEmpty ? null : _attachmentUrls,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Homework Assigned Successfully! 📚'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create homework: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectAndUploadFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploadingFiles = true;
        _uploadProgress = 0.0;
      });

      final files = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      if (files.isEmpty) {
        setState(() => _isUploadingFiles = false);
        return;
      }

      // Upload files to Firebase Storage
      final uploadedUrls = await _storageService.uploadFiles(
        files: files,
        path: 'homework_attachments',
        onProgress: (current, total, progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      setState(() {
        _attachmentUrls.addAll(uploadedUrls);
        _isUploadingFiles = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadedUrls.length} file(s) uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingFiles = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Assign Homework", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class and Section Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            "Class *",
                            _availableClasses,
                            _selectedClass,
                            (v) => setState(() => _selectedClass = v),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDropdown(
                            "Section *",
                            _availableSections,
                            _selectedSection,
                            (v) => setState(() => _selectedSection = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Subject Dropdown
                    _buildDropdown(
                      "Subject *",
                      _availableSubjects,
                      _selectedSubject,
                      (v) => setState(() => _selectedSubject = v),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Title / Topic *"),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputStyle("e.g. Algebra Ex 4.2"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    _buildLabel("Instructions"),
                    TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: _inputStyle("Enter detailed instructions here..."),
                    ),

                    const SizedBox(height: 20),
                    _buildLabel("Submission Deadline *"),
                    GestureDetector(
                      onTap: _selectDueDate,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.teal),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMM yyyy').format(_dueDate),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (_attachmentUrls.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachmentUrls.map((url) {
                          return Chip(
                            label: Text(url.split('/').last),
                            onDeleted: () {
                              setState(() => _attachmentUrls.remove(url));
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: _isUploadingFiles ? null : _selectAndUploadFiles,
                      icon: _isUploadingFiles
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: _uploadProgress,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                              ),
                            )
                          : const Icon(Icons.attach_file, color: Colors.teal),
                      label: Text(
                        _isUploadingFiles
                            ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                            : "Attach File (Optional)",
                        style: const TextStyle(color: Colors.teal),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text("Assign to Class", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? val, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              isExpanded: true,
              hint: Text('Select $label'),
              items: items.map((e) {
                final displayText = label.contains('Class') ? 'Class $e' : 
                                   label.contains('Section') ? 'Section $e' : e;
                return DropdownMenuItem(value: e, child: Text(displayText));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)));

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}