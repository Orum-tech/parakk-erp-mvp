import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../services/marks_service.dart';
import '../../services/marksheet_service.dart';
import '../../models/marks_model.dart';
import '../../models/student_model.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final MarksService _marksService = MarksService();
  final MarksheetService _marksheetService = MarksheetService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StudentModel? _student;
  String? _selectedExamId;
  String? _lastCalculatedExamId; // Track which exam we calculated rank for
  bool _isLoadingStudent = true;
  int? _studentRank;
  bool _isLoadingRank = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoadingStudent = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoadingStudent = false);
        return;
      }

      // Get student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (studentDoc.exists) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudent = false);
      }
    }
  }

  List<String> _availableExamIds(List<MarksModel> marks) {
    return marks.map((m) => m.examId).toSet().toList();
  }

  List<MarksModel> _filteredMarks(List<MarksModel> allMarks) {
    if (_selectedExamId == null) return [];
    return allMarks.where((m) => m.examId == _selectedExamId).toList();
  }

  String _selectedExamName(List<MarksModel> filteredMarks) {
    if (_selectedExamId == null || filteredMarks.isEmpty) return 'No Exam Selected';
    return filteredMarks.first.examName;
  }

  double _calculateCGPA(List<MarksModel> filteredMarks) {
    if (filteredMarks.isEmpty) return 0.0;

    double totalPoints = 0.0;
    int count = 0;

    for (var mark in filteredMarks) {
      final grade = mark.grade ?? mark.calculateGrade();
      double points;
      switch (grade) {
        case 'A+':
          points = 10.0;
          break;
        case 'A':
          points = 9.0;
          break;
        case 'B+':
          points = 8.0;
          break;
        case 'B':
          points = 7.0;
          break;
        case 'C+':
          points = 6.0;
          break;
        case 'C':
          points = 5.0;
          break;
        default:
          points = 0.0;
      }
      totalPoints += points;
      count++;
    }

    return count > 0 ? totalPoints / count : 0.0;
  }

  String _overallGrade(List<MarksModel> filteredMarks) {
    final cgpa = _calculateCGPA(filteredMarks);
    if (cgpa >= 9.0) return 'A+ (Excellent)';
    if (cgpa >= 8.0) return 'A (Very Good)';
    if (cgpa >= 7.0) return 'B+ (Good)';
    if (cgpa >= 6.0) return 'B (Satisfactory)';
    if (cgpa >= 5.0) return 'C+ (Average)';
    if (cgpa >= 4.0) return 'C (Below Average)';
    return 'F (Fail)';
  }

  Future<void> _calculateRank() async {
    if (_selectedExamId == null || _student?.classId == null) {
      setState(() {
        _studentRank = null;
        _lastCalculatedExamId = null;
      });
      return;
    }

    // Don't recalculate if we already calculated for this exam
    if (_selectedExamId == _lastCalculatedExamId && _studentRank != null) {
      return;
    }

    setState(() {
      _isLoadingRank = true;
      _lastCalculatedExamId = _selectedExamId;
    });

    try {
      final rank = await _marksService.calculateStudentRank(
        _auth.currentUser!.uid,
        _selectedExamId!,
        _student!.classId!,
      );
      if (mounted) {
        setState(() {
          _studentRank = rank;
          _isLoadingRank = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentRank = null;
          _isLoadingRank = false;
        });
        debugPrint('Error calculating rank: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStudent) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Performance Report", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Performance Report", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: Text('Please log in to view results')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Performance Report", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              // Share functionality
            },
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<MarksModel>>(
        stream: _marksService.getStudentMarks(user.uid),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading results: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final allMarks = snapshot.data ?? [];

          // Handle empty state - show immediately
          if (allMarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No results available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your marks will appear here once they are entered',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Auto-select first exam if none selected
          if (_selectedExamId == null && allMarks.isNotEmpty) {
            final examIds = allMarks.map((m) => m.examId).toSet().toList();
            if (examIds.isNotEmpty && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedExamId = examIds.first;
                  });
                  // Calculate rank after selecting exam
                  _calculateRank();
                }
              });
            }
          }


          final filteredMarks = _filteredMarks(allMarks);
          final availableExamIds = _availableExamIds(allMarks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Exam Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedExamId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: availableExamIds.map((examId) {
                      final examMarks = allMarks.where((m) => m.examId == examId).toList();
                      final examName = examMarks.isNotEmpty ? examMarks.first.examName : 'Exam';
                      return DropdownMenuItem(
                        value: examId,
                        child: Text(examName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExamId = value;
                        _studentRank = null; // Reset rank when exam changes
                        _lastCalculatedExamId = null; // Reset tracking
                      });
                      // Calculate rank for new exam
                      if (value != null) {
                        _calculateRank();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 25),

                // Score Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF303F9F), Color(0xFF5C6BC0)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF303F9F).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("CGPA Score", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      Text(
                        _calculateCGPA(filteredMarks).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        _overallGrade(filteredMarks),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      if (_isLoadingRank) ...[
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ] else if (_studentRank != null && _studentRank! > 0) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _studentRank == 1
                                    ? Icons.emoji_events
                                    : _studentRank! <= 3
                                        ? Icons.star
                                        : Icons.trending_up,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rank: $_studentRank${_studentRank == 1 ? 'st' : _studentRank == 2 ? 'nd' : _studentRank == 3 ? 'rd' : 'th'} in Class',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Subject Wise Breakdown
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Subject Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),

                if (filteredMarks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No marks available for this exam'),
                    ),
                  )
                else
                  ...filteredMarks.map((mark) {
                    final percentage = mark.percentage;
                    Color color;
                    if (percentage >= 90) {
                      color = Colors.green;
                    } else if (percentage >= 80) {
                      color = Colors.blue;
                    } else if (percentage >= 70) {
                      color = Colors.orange;
                    } else if (percentage >= 60) {
                      color = Colors.purple;
                    } else if (percentage >= 40) {
                      color = Colors.redAccent;
                    } else {
                      color = Colors.red;
                    }

                    return _buildSubjectRow(
                      mark.subjectName,
                      mark.marksObtained,
                      mark.maxMarks,
                      mark.grade ?? mark.calculateGrade(),
                      percentage,
                      color,
                    );
                  }),

                const SizedBox(height: 30),

                // Download Button
                ElevatedButton.icon(
                  onPressed: filteredMarks.isEmpty || _student == null
                      ? null
                      : () => _downloadMarksheet(filteredMarks),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text("Download Full Marksheet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectRow(String subject, int marks, int total, String grade, double percentage, Color color) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$marks/$total",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    grade,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: marks / total,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadMarksheet(List<MarksModel> marks) async {
    if (_student == null || _selectedExamId == null || marks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to generate marksheet. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating marksheet...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final examName = marks.isNotEmpty ? marks.first.examName : 'Exam';
      final examDate = marks.isNotEmpty && marks.first.examDate != null
          ? DateFormat('dd MMM yyyy').format(marks.first.examDate!)
          : null;

      // Generate PDF
      final pdfFile = await _marksheetService.generateMarksheetPDF(
        student: _student!,
        marks: marks,
        examName: examName,
        examDate: examDate,
        cgpa: _calculateCGPA(marks),
        overallGrade: _overallGrade(marks),
        rank: _studentRank,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show options dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Marksheet Generated'),
            content: const Text('What would you like to do with the marksheet?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareMarksheet(pdfFile);
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _viewMarksheet(pdfFile);
                },
                child: const Text('View'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareMarksheet(pdfFile);
                },
                child: const Text('Download'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating marksheet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error generating marksheet: $e');
    }
  }

  Future<void> _shareMarksheet(File pdfFile) async {
    try {
      final xFile = XFile(pdfFile.path);
      
      // Get exam name from file name
      final fileName = pdfFile.path.split('/').last;
      String examName = 'Exam';
      if (fileName.contains('_')) {
        final parts = fileName.split('_');
        if (parts.length >= 3) {
          examName = parts.sublist(2, parts.length - 1).join(' ').replaceAll('_', ' ');
        }
      }
      
      await Share.shareXFiles(
        [xFile],
        text: 'My marksheet from $examName',
        subject: 'Marksheet - ${_student?.name ?? 'Student'}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing marksheet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewMarksheet(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing marksheet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
