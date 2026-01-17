import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/test_model.dart';
import '../../models/student_model.dart';
import '../../services/test_service.dart';
import 'test_taking_screen.dart';

class PracticeTestsScreen extends StatefulWidget {
  const PracticeTestsScreen({super.key});

  @override
  State<PracticeTestsScreen> createState() => _PracticeTestsScreenState();
}

class _PracticeTestsScreenState extends State<PracticeTestsScreen> {
  final TestService _testService = TestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentModel? _student;
  String? _selectedSubject;
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    }
  }

  Color _getTestTypeColor(TestType type) {
    switch (type) {
      case TestType.quiz:
        return Colors.orange;
      case TestType.mockTest:
        return Colors.blue;
      case TestType.assignment:
        return Colors.purple;
      case TestType.practice:
        return Colors.green;
    }
  }

  String _getTestTypeLabel(TestType type) {
    switch (type) {
      case TestType.quiz:
        return 'Quiz';
      case TestType.mockTest:
        return 'Mock Test';
      case TestType.assignment:
        return 'Assignment';
      case TestType.practice:
        return 'Practice';
    }
  }

  bool _isTestAvailable(TestModel test) {
    final now = DateTime.now();
    if (now.isBefore(test.startDate)) return false;
    if (test.endDate != null && now.isAfter(test.endDate!)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Practice Tests", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<TestModel>>(
        stream: _student?.classId != null
            ? _testService.getStudentTests(_student!.classId)
            : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tests: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final tests = snapshot.data ?? [];

          if (tests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tests available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tests will appear here once teachers create them',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Get unique subjects
          final subjects = tests.map((t) => t.subject).toSet().toList()..sort();
          if (_subjects.isEmpty) {
            _subjects = subjects;
          }

          final filteredTests = _selectedSubject == null
              ? tests
              : tests.where((t) => t.subject == _selectedSubject).toList();

          return Column(
            children: [
              // Subject Filter
              if (subjects.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSubjectChip(null, 'All'),
                      ...subjects.map((subject) => _buildSubjectChip(subject, subject)),
                    ],
                  ),
                ),
              // Test List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ...filteredTests.map((test) => _buildTestCard(test)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubjectChip(String? subject, String label) {
    final isSelected = _selectedSubject == subject;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSubject = selected ? subject : null;
          });
        },
      ),
    );
  }

  Widget _buildTestCard(TestModel test) {
    final color = _getTestTypeColor(test.testType);
    final isAvailable = _isTestAvailable(test);
    final now = DateTime.now();
    final isUpcoming = now.isBefore(test.startDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
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
                      test.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      test.description,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTestTypeLabel(test.testType),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (test.chapter != null || test.topic != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (test.chapter != null) ...[
                  Icon(Icons.menu_book, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    test.chapter!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
                if (test.chapter != null && test.topic != null)
                  Text(' • ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                if (test.topic != null) ...[
                  Icon(Icons.topic, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    test.topic!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(
                '${test.duration} Mins',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(width: 20),
              Icon(Icons.format_list_numbered, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(
                '${test.questionCount} Questions',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(width: 20),
              Icon(Icons.star, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(
                '${test.totalMarks} Marks',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Starts: ${DateFormat('dd MMM yyyy').format(test.startDate)}',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else if (test.endDate != null && now.isBefore(test.endDate!)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Ends: ${DateFormat('dd MMM yyyy').format(test.endDate!)}',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAvailable
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestTakingScreen(test: test),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(isUpcoming ? 'Upcoming' : (isAvailable ? 'Start Test' : 'Expired')),
            ),
          ),
        ],
      ),
    );
  }
}