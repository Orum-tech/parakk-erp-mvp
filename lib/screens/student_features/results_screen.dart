import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/marks_service.dart';
import '../../models/marks_model.dart';
import '../../models/student_model.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final MarksService _marksService = MarksService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StudentModel? _student;
  List<MarksModel> _allMarks = [];
  String? _selectedExamId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
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

      // Load marks
      _marksService.getStudentMarks(user.uid).listen((marks) {
        if (mounted) {
          setState(() {
            _allMarks = marks;
            if (_selectedExamId == null && marks.isNotEmpty) {
              // Group by exam and select the most recent
              final examIds = marks.map((m) => m.examId).toSet().toList();
              if (examIds.isNotEmpty) {
                _selectedExamId = examIds.first;
              }
            }
            _isLoading = false;
          });
        }
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

  List<String> get _availableExamIds {
    return _allMarks.map((m) => m.examId).toSet().toList();
  }

  List<MarksModel> get _filteredMarks {
    if (_selectedExamId == null) return [];
    return _allMarks.where((m) => m.examId == _selectedExamId).toList();
  }

  String get _selectedExamName {
    if (_selectedExamId == null || _filteredMarks.isEmpty) return 'No Exam Selected';
    return _filteredMarks.first.examName;
  }

  double get _calculateCGPA {
    if (_filteredMarks.isEmpty) return 0.0;

    double totalPoints = 0.0;
    int count = 0;

    for (var mark in _filteredMarks) {
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

  String get _overallGrade {
    final cgpa = _calculateCGPA;
    if (cgpa >= 9.0) return 'A+ (Excellent)';
    if (cgpa >= 8.0) return 'A (Very Good)';
    if (cgpa >= 7.0) return 'B+ (Good)';
    if (cgpa >= 6.0) return 'B (Satisfactory)';
    if (cgpa >= 5.0) return 'C+ (Average)';
    if (cgpa >= 4.0) return 'C (Below Average)';
    return 'F (Fail)';
  }

  int get _rank {
    // This would require comparing with other students' marks
    // For now, return a placeholder
    return 0; // Would need to calculate from all students' marks
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_allMarks.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Performance Report", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
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
        ),
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
      body: SingleChildScrollView(
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
                items: _availableExamIds.map((examId) {
                  final examMarks = _allMarks.where((m) => m.examId == examId).toList();
                  final examName = examMarks.isNotEmpty ? examMarks.first.examName : 'Exam';
                  return DropdownMenuItem(
                    value: examId,
                    child: Text(examName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExamId = value;
                  });
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
                    _calculateCGPA.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _overallGrade,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  if (_rank > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Rank: ${_rank}${_rank == 1 ? 'st' : _rank == 2 ? 'nd' : _rank == 3 ? 'rd' : 'th'} in Class',
                        style: const TextStyle(color: Colors.white),
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

            if (_filteredMarks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No marks available for this exam'),
                ),
              )
            else
              ..._filteredMarks.map((mark) {
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
              onPressed: () {
                // Download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download feature coming soon')),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text("Download Full Marksheet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
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
}
