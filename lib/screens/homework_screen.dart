import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/homework_service.dart';
import '../services/auth_service.dart';
import '../models/homework_model.dart';
import '../models/homework_submission_model.dart';
import 'student_features/homework_submission_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _homeworkService = HomeworkService();
  final _authService = AuthService();
  String? _studentClassId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudentClass();
  }

  Future<void> _loadStudentClass() async {
    try {
      final user = await _authService.getCurrentUserWithData();
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _studentClassId = userDoc.data()!['classId'];
          });
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Assignments", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1565C0),
          tabs: const [
            Tab(text: "To Do"),
            Tab(text: "Submitted"),
            Tab(text: "Graded"),
          ],
        ),
      ),
      body: _studentClassId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildToDoList(),
                _buildSubmittedList(),
                _buildGradedList(),
              ],
            ),
    );
  }

  Widget _buildToDoList() {
    return StreamBuilder<List<HomeworkModel>>(
      stream: _homeworkService.getStudentHomework(_studentClassId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final homeworkList = snapshot.data ?? [];
        
        // Filter to only show homework without submissions
        return FutureBuilder<List<HomeworkModel>>(
          future: _filterUnsubmittedHomework(homeworkList),
          builder: (context, filteredSnapshot) {
            final filteredList = filteredSnapshot.data ?? [];

            if (filteredList.isEmpty) {
              return const Center(
                child: Text(
                  "No pending assignments",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: filteredList.map((hw) => _buildHomeworkCard(hw, isPending: true)).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmittedList() {
    return StreamBuilder<List<HomeworkModel>>(
      stream: _homeworkService.getStudentHomework(_studentClassId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final homeworkList = snapshot.data ?? [];
        
        return FutureBuilder<List<HomeworkModel>>(
          future: _filterSubmittedHomework(homeworkList),
          builder: (context, filteredSnapshot) {
            final filteredList = filteredSnapshot.data ?? [];

            if (filteredList.isEmpty) {
              return const Center(
                child: Text(
                  "No submitted assignments",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: filteredList.map((hw) => _buildHomeworkCard(hw, isPending: false)).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildGradedList() {
    return StreamBuilder<List<HomeworkModel>>(
      stream: _homeworkService.getStudentHomework(_studentClassId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final homeworkList = snapshot.data ?? [];
        
        return FutureBuilder<List<HomeworkModel>>(
          future: _filterGradedHomework(homeworkList),
          builder: (context, filteredSnapshot) {
            final filteredList = filteredSnapshot.data ?? [];

            if (filteredList.isEmpty) {
              return const Center(
                child: Text(
                  "No graded assignments",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: filteredList.map((hw) => _buildHomeworkCard(hw, isPending: false, isGraded: true)).toList(),
            );
          },
        );
      },
    );
  }

  Future<List<HomeworkModel>> _filterUnsubmittedHomework(List<HomeworkModel> homeworkList) async {
    final unsubmitted = <HomeworkModel>[];
    for (final hw in homeworkList) {
      final submission = await _homeworkService.getStudentSubmission(hw.homeworkId);
      if (submission == null) {
        unsubmitted.add(hw);
      }
    }
    return unsubmitted;
  }

  Future<List<HomeworkModel>> _filterSubmittedHomework(List<HomeworkModel> homeworkList) async {
    final submitted = <HomeworkModel>[];
    for (final hw in homeworkList) {
      final submission = await _homeworkService.getStudentSubmission(hw.homeworkId);
      if (submission != null && !submission.isGraded) {
        submitted.add(hw);
      }
    }
    return submitted;
  }

  Future<List<HomeworkModel>> _filterGradedHomework(List<HomeworkModel> homeworkList) async {
    final graded = <HomeworkModel>[];
    for (final hw in homeworkList) {
      final submission = await _homeworkService.getStudentSubmission(hw.homeworkId);
      if (submission != null && submission.isGraded) {
        graded.add(hw);
      }
    }
    return graded;
  }

  Widget _buildHomeworkCard(HomeworkModel hw, {required bool isPending, bool isGraded = false}) {
    final isOverdue = hw.isOverdue;
    final subjectColors = {
      'Mathematics': Colors.orange,
      'Physics': Colors.blue,
      'Chemistry': Colors.purple,
      'Biology': Colors.green,
      'English': Colors.redAccent,
    };
    final color = subjectColors[hw.subjectName] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue && isPending
            ? Border.all(color: Colors.red, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hw.subjectName,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isPending)
                Text(
                  isOverdue ? "Overdue" : "Due: ${DateFormat('dd MMM').format(hw.dueDate)}",
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              if (isGraded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Graded",
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hw.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (hw.description != null && hw.description!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              hw.description!,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                hw.teacherName,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd MMM yyyy').format(hw.dueDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (isPending)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeworkSubmissionScreen(homework: hw),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Submit Assignment"),
            )
          else if (isGraded)
            FutureBuilder<HomeworkSubmissionModel?>(
              future: _homeworkService.getStudentSubmission(hw.homeworkId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final submission = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            'Marks: ${submission.marksObtained ?? 0}/${submission.maxMarks ?? 100}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Feedback: ${submission.feedback}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
        ],
      ),
    );
  }
}