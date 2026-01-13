import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/marks_service.dart';
import '../../models/student_model.dart';
import '../../models/exam_model.dart';

class MarksEntryScreen extends StatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final MarksService _marksService = MarksService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Selection state
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedExamId;
  ExamModel? _selectedExam;

  // Data lists
  List<Map<String, String>> _classes = [];
  List<Map<String, String>> _subjects = [];
  List<StudentModel> _students = [];
  List<ExamModel> _exams = [];

  // Marks entry
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  // Form state
  bool _isLoading = true;
  bool _isSaving = false;
  int _maxMarks = 100;
  DateTime _examDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
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

      final classes = await _marksService.getTeacherClasses(user.uid);
      final subjects = await _marksService.getTeacherSubjects(user.uid);

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

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;

    setState(() => _isLoading = true);
    try {
      final students = await _marksService.getStudentsByClass(_selectedClassId!);

      // Initialize controllers
      for (var student in students) {
        if (!_marksControllers.containsKey(student.uid)) {
          _marksControllers[student.uid] = TextEditingController();
        }
        if (!_remarksControllers.containsKey(student.uid)) {
          _remarksControllers[student.uid] = TextEditingController();
        }
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });
      
      // Load existing marks if exam is already selected
      if (_selectedExamId != null) {
        _loadExistingMarks();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadExams() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;

    try {
      final exams = await _marksService.getExamsByClassAndSubject(
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
      );

      setState(() {
        _exams = exams;
        if (exams.isNotEmpty && _selectedExamId == null) {
          _selectedExam = exams.first;
          _selectedExamId = exams.first.examId;
          _maxMarks = exams.first.maxMarks;
          _examDate = exams.first.examDate;
        }
      });
      
      // Load existing marks if exam is already selected and students are loaded
      if (_selectedExamId != null && _students.isNotEmpty) {
        _loadExistingMarks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exams: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _clearMarksControllers() {
    // Clear all marks and remarks controllers
    for (var controller in _marksControllers.values) {
      controller.clear();
    }
    for (var controller in _remarksControllers.values) {
      controller.clear();
    }
  }

  Future<void> _loadExistingMarks() async {
    if (_selectedExamId == null || _students.isEmpty) return;

    try {
      final existingMarks = await _marksService.getMarksByExam(_selectedExamId!);
      
      // Create a map of studentId -> marks for quick lookup
      final marksMap = {for (var m in existingMarks) m.studentId: m};

      // Populate controllers with existing marks
      for (var student in _students) {
        final existingMark = marksMap[student.uid];
        if (existingMark != null) {
          // Set marks controller
          if (!_marksControllers.containsKey(student.uid)) {
            _marksControllers[student.uid] = TextEditingController();
          }
          _marksControllers[student.uid]!.text = existingMark.marksObtained.toString();
          
          // Set remarks controller
          if (existingMark.remarks != null && existingMark.remarks!.isNotEmpty) {
            if (!_remarksControllers.containsKey(student.uid)) {
              _remarksControllers[student.uid] = TextEditingController();
            }
            _remarksControllers[student.uid]!.text = existingMark.remarks!;
          }
        } else {
          // Clear controllers if no marks exist for this student
          _marksControllers[student.uid]?.clear();
          _remarksControllers[student.uid]?.clear();
        }
      }
      
      setState(() {}); // Refresh UI to show loaded marks
    } catch (e) {
      // Silently fail - it's okay if marks don't exist yet
      if (mounted) {
        debugPrint('Error loading existing marks: $e');
      }
    }
  }

  Future<void> _createNewExam() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;

    final examNameController = TextEditingController();
    final maxMarksController = TextEditingController(text: '100');
    ExamType selectedType = ExamType.midTerm;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Exam'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: examNameController,
                decoration: const InputDecoration(
                  labelText: 'Exam Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExamType>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Exam Type *',
                  border: OutlineInputBorder(),
                ),
                items: ExamType.values.map((type) {
                  String label;
                  switch (type) {
                    case ExamType.unitTest:
                      label = 'Unit Test';
                      break;
                    case ExamType.midTerm:
                      label = 'Mid-Term';
                      break;
                    case ExamType.finalExam:
                      label = 'Final Exam';
                      break;
                    case ExamType.quiz:
                      label = 'Quiz';
                      break;
                    case ExamType.assignment:
                      label = 'Assignment';
                      break;
                    case ExamType.project:
                      label = 'Project';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxMarksController,
                decoration: const InputDecoration(
                  labelText: 'Max Marks *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (examNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter exam name'), backgroundColor: Colors.red),
                );
                return;
              }
              final maxMarks = int.tryParse(maxMarksController.text) ?? 100;
              Navigator.pop(context, {
                'examName': examNameController.text.trim(),
                'examType': selectedType,
                'maxMarks': maxMarks,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final examId = await _marksService.createOrUpdateExam(
          examName: result['examName'],
          examType: result['examType'],
          classId: _selectedClassId!,
          className: _selectedClassName!,
          subjectId: _selectedSubjectId!,
          subjectName: _selectedSubjectName!,
          examDate: _examDate,
          maxMarks: result['maxMarks'],
        );

        await _loadExams();
        setState(() {
          _selectedExamId = examId;
          _maxMarks = result['maxMarks'];
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating exam: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _saveMarks() async {
    if (_selectedClassId == null || _selectedSubjectId == null || _selectedExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class, subject, and exam'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final studentMarks = <String, int>{};
    final studentRemarks = <String, String>{};

    for (var student in _students) {
      final marksText = _marksControllers[student.uid]?.text.trim() ?? '';
      if (marksText.isNotEmpty) {
        final marks = int.tryParse(marksText);
        if (marks != null && marks >= 0 && marks <= _maxMarks) {
          studentMarks[student.uid] = marks;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid marks for ${student.name}. Must be between 0 and $_maxMarks'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final remarks = _remarksControllers[student.uid]?.text.trim();
      if (remarks != null && remarks.isNotEmpty) {
        studentRemarks[student.uid] = remarks;
      }
    }

    if (studentMarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter marks for at least one student'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _marksService.saveMarks(
        examId: _selectedExamId!,
        examName: _selectedExam?.examName ?? 'Exam',
        classId: _selectedClassId!,
        className: _selectedClassName!,
        subjectId: _selectedSubjectId!,
        subjectName: _selectedSubjectName!,
        maxMarks: _maxMarks,
        examDate: _examDate,
        studentMarks: studentMarks,
        studentRemarks: studentRemarks.isNotEmpty ? studentRemarks : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks saved successfully! ✅'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _classes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("Enter Marks", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Enter Marks", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Selection Section
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              children: [
                // Class Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Select Class *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.class_),
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
                      _students = [];
                      _selectedSubjectId = null;
                      _selectedExamId = null;
                      _selectedExam = null;
                    });
                    // Clear marks controllers when class changes
                    _clearMarksControllers();
                    if (value != null) {
                      _loadStudents();
                    }
                  },
                ),
                const SizedBox(height: 15),
                // Subject Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Select Subject *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subject),
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
                      _selectedExamId = null;
                      _selectedExam = null;
                    });
                    // Clear marks controllers when subject changes
                    _clearMarksControllers();
                    if (value != null && _selectedClassId != null) {
                      _loadExams();
                    }
                  },
                ),
                const SizedBox(height: 15),
                // Exam Selection
                if (_selectedClassId != null && _selectedSubjectId != null)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedExamId,
                          decoration: const InputDecoration(
                            labelText: 'Select Exam *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.quiz),
                          ),
                          items: _exams.map((exam) {
                            return DropdownMenuItem(
                              value: exam.examId,
                              child: Text('${exam.examName} (${exam.examTypeString})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedExamId = value;
                              _selectedExam = _exams.firstWhere((e) => e.examId == value);
                              _maxMarks = _selectedExam!.maxMarks;
                              _examDate = _selectedExam!.examDate;
                            });
                            // Load existing marks for this exam
                            if (value != null && _students.isNotEmpty) {
                              _loadExistingMarks();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Colors.teal,
                        onPressed: _createNewExam,
                        tooltip: 'Create New Exam',
                      ),
                    ],
                  ),
                if (_selectedExam != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Max Marks: $_maxMarks',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Date: ${_examDate.day}/${_examDate.month}/${_examDate.year}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Students List
          Expanded(
            child: _students.isEmpty
                ? Center(
                    child: Text(
                      _selectedClassId == null
                          ? 'Please select a class'
                          : 'No students found in this class',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(15),
                    itemCount: _students.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}.',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (student.rollNumber != null)
                                    Text(
                                      'Roll: ${student.rollNumber}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _marksControllers[student.uid],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "0",
                                  border: InputBorder.none,
                                  constraints: const BoxConstraints(maxHeight: 40),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.note_add, size: 20),
                              color: Colors.grey[600],
                              onPressed: () => _showRemarksDialog(student),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedExamId != null && _students.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveMarks,
              backgroundColor: const Color(0xFF00897B),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save All',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Future<void> _showRemarksDialog(StudentModel student) async {
    final controller = _remarksControllers[student.uid] ?? TextEditingController();
    _remarksControllers[student.uid] = controller;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Remarks for ${student.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter remarks (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
