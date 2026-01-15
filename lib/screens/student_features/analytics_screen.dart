import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/attendance_service.dart';
import '../../services/marks_service.dart';
import '../../services/homework_service.dart';
import '../../models/student_model.dart';
import '../../models/marks_model.dart';
import '../../models/attendance_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final MarksService _marksService = MarksService();
  final HomeworkService _homeworkService = HomeworkService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentModel? _student;
  Map<String, dynamic>? _attendanceStats;
  List<MarksModel> _allMarks = [];
  Map<String, double> _subjectAverages = {};
  Map<String, int> _monthlyAttendance = {};
  List<Map<String, dynamic>> _examScores = [];
  double _homeworkCompletionRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load student data
      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });
      }

      // Load attendance stats
      final stats = await _attendanceService.getStudentAttendanceStats(user.uid);
      setState(() {
        _attendanceStats = stats;
      });

      // Load monthly attendance
      await _loadMonthlyAttendance(user.uid);

      // Load marks
      _marksService.getStudentMarks(user.uid).listen((marks) {
        if (mounted) {
          setState(() {
            _allMarks = marks;
            _calculateSubjectAverages();
            _calculateExamScores();
          });
        }
      });

      // Load homework completion rate
      if (_student?.classId != null) {
        await _loadHomeworkCompletionRate();
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonthlyAttendance(String studentId) async {
    try {
      final now = DateTime.now();
      final monthlyData = <String, int>{};

      // Get last 6 months
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        // Get attendance for this month
        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
        
        final attendance = await _attendanceService
            .getStudentAttendance(studentId: studentId, startDate: startOfMonth, endDate: endOfMonth)
            .first;
        
        final presentCount = attendance.where((a) => a.status == AttendanceStatus.present).length;
        final totalDays = attendance.length;
        
        if (totalDays > 0) {
          monthlyData[monthKey] = ((presentCount / totalDays) * 100).round();
        } else {
          monthlyData[monthKey] = 0;
        }
      }

      setState(() {
        _monthlyAttendance = monthlyData;
      });
    } catch (e) {
      debugPrint('Error loading monthly attendance: $e');
    }
  }

  void _calculateSubjectAverages() {
    final subjectTotals = <String, List<double>>{};

    for (var mark in _allMarks) {
      if (!subjectTotals.containsKey(mark.subjectName)) {
        subjectTotals[mark.subjectName] = [];
      }
      subjectTotals[mark.subjectName]!.add(mark.percentage);
    }

    final averages = <String, double>{};
    subjectTotals.forEach((subject, percentages) {
      if (percentages.isNotEmpty) {
        averages[subject] = percentages.reduce((a, b) => a + b) / percentages.length;
      }
    });

    setState(() {
      _subjectAverages = averages;
    });
  }

  void _calculateExamScores() {
    final examScores = <Map<String, dynamic>>[];
    final examGroups = <String, List<MarksModel>>{};

    // Group marks by exam
    for (var mark in _allMarks) {
      if (!examGroups.containsKey(mark.examName)) {
        examGroups[mark.examName] = [];
      }
      examGroups[mark.examName]!.add(mark);
    }

    // Calculate average for each exam
    examGroups.forEach((examName, marks) {
      if (marks.isNotEmpty) {
        final avgPercentage = marks.map((m) => m.percentage).reduce((a, b) => a + b) / marks.length;
        examScores.add({
          'examName': examName,
          'percentage': avgPercentage,
          'date': marks.first.examDate ?? marks.first.createdAt.toDate(),
        });
      }
    });

    // Sort by date
    examScores.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateA.compareTo(dateB);
    });

    setState(() {
      _examScores = examScores;
    });
  }

  Future<void> _loadHomeworkCompletionRate() async {
    if (_student?.classId == null) return;
    try {
      final homework = await _homeworkService.getStudentHomework(_student!.classId!).first;
      if (homework.isEmpty) {
        setState(() => _homeworkCompletionRate = 0.0);
        return;
      }

      int completed = 0;
      for (var hw in homework) {
        final submission = await _homeworkService.getStudentSubmission(hw.homeworkId);
        if (submission != null && submission.isGraded) {
          completed++;
        }
      }

      setState(() {
        _homeworkCompletionRate = homework.isEmpty ? 0.0 : (completed / homework.length);
      });
    } catch (e) {
      debugPrint('Error loading homework completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("My Performance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: const Text("My Performance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Stats Card
              if (_attendanceStats != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Attendance',
                        '${_attendanceStats!['overallPercentage']?.toStringAsFixed(1) ?? '0'}%',
                        Icons.check_circle,
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                      _buildStatItem(
                        'Subjects',
                        '${_subjectAverages.length}',
                        Icons.menu_book,
                      ),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                      _buildStatItem(
                        'Homework',
                        '${(_homeworkCompletionRate * 100).toStringAsFixed(0)}%',
                        Icons.assignment,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 25),

              // Attendance Trends
              _buildChartCard(
                "Attendance Trends",
                "Last 6 Months",
                Colors.green,
                Icons.show_chart_rounded,
                _buildAttendanceChart(),
              ),
              
              const SizedBox(height: 20),

              // Academic Growth
              _buildChartCard(
                "Academic Growth",
                "Exam Wise Score",
                Colors.blue,
                Icons.bar_chart_rounded,
                _buildExamScoresChart(),
              ),
              
              const SizedBox(height: 20),

              // Subject Strength
              _buildChartCard(
                "Subject Performance",
                "Average Scores",
                Colors.purple,
                Icons.pie_chart_rounded,
                _buildSubjectPerformance(),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, String sub, Color color, IconData icon, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    sub,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_monthlyAttendance.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No attendance data available",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    final months = _monthlyAttendance.keys.toList();
    final values = _monthlyAttendance.values.toList();
    final maxValue = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(months.length, (index) {
          final monthName = _getMonthName(months[index]);
          final value = values[index];
          final height = maxValue > 0 ? (value / maxValue) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      height: double.infinity,
                      child: FractionallySizedBox(
                        heightFactor: height,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.green.shade300, Colors.green.shade600],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExamScoresChart() {
    if (_examScores.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No exam data available",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    // Show last 5 exams
    final recentExams = _examScores.length > 5
        ? _examScores.sublist(_examScores.length - 5)
        : _examScores;

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(recentExams.length, (index) {
          final exam = recentExams[index];
          final percentage = exam['percentage'] as double;
          final examName = exam['examName'] as String;
          final height = percentage / 100;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      height: double.infinity,
                      child: FractionallySizedBox(
                        heightFactor: height,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.blue.shade300, Colors.blue.shade600],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    examName.length > 8 ? '${examName.substring(0, 8)}...' : examName,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubjectPerformance() {
    if (_subjectAverages.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No subject data available",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    final sortedSubjects = _subjectAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedSubjects.map((entry) {
        final percentage = entry.value;
        Color color;
        if (percentage >= 80) {
          color = Colors.green;
        } else if (percentage >= 60) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getMonthName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    
    final month = int.tryParse(parts[1]);
    if (month == null) return monthKey;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return monthKey;
  }
}
