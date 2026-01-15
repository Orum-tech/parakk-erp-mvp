import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/attendance_service.dart';
import '../../services/marks_service.dart';
import '../../services/homework_service.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../models/marks_model.dart';
import '../../models/attendance_model.dart';

class ClassAnalyticsScreen extends StatefulWidget {
  const ClassAnalyticsScreen({super.key});

  @override
  State<ClassAnalyticsScreen> createState() => _ClassAnalyticsScreenState();
}

class _ClassAnalyticsScreenState extends State<ClassAnalyticsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final MarksService _marksService = MarksService();
  final HomeworkService _homeworkService = HomeworkService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _classId;
  String? _className;
  TeacherModel? _teacher;
  List<StudentModel> _students = [];
  Map<String, double> _dayAttendance = {};
  Map<String, double> _subjectAverages = {};
  Map<String, int> _performanceDistribution = {'Excellent': 0, 'Good': 0, 'Average': 0, 'Below Average': 0};
  double _homeworkSubmissionRate = 0.0;
  double _overallAttendance = 0.0;
  bool _isLoading = true;
  bool _hasPermission = false;

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

      // Load teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        setState(() {
          _teacher = TeacherModel.fromDocument(teacherDoc);
        });
      }

      // Get class teacher's class
      final classId = await _attendanceService.getClassTeacherClassId();
      
      if (classId == null) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      // Verify permission
      final hasPermission = await _attendanceService.isClassTeacherForClass(classId);
      if (!hasPermission) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _classId = classId;
        _hasPermission = true;
      });

      // Parse className from classId
      final parts = classId.replaceFirst('class_', '').split('_');
      if (parts.length == 2) {
        setState(() {
          _className = 'Class ${parts[0]}-${parts[1]}';
        });
      }

      // Load students
      final students = await _attendanceService.getStudentsByClass(classId);
      setState(() {
        _students = students;
      });

      // Load all analytics
      await Future.wait([
        _loadDayAttendance(),
        _loadSubjectAverages(),
        _loadPerformanceDistribution(),
        _loadHomeworkSubmissionRate(),
        _loadOverallAttendance(),
      ]);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDayAttendance() async {
    if (_classId == null) return;
    try {
      final now = DateTime.now();
      final dayAttendance = <String, List<int>>{};
      
      // Get last 5 weekdays
      for (int i = 0; i < 5; i++) {
        final date = now.subtract(Duration(days: i));
        // Skip weekends
        if (date.weekday > 5) continue;
        
        final dayName = _getDayName(date.weekday);
        final attendance = await _attendanceService
            .getAttendanceByDateAndClass(classId: _classId!, date: date)
            .first;
        
        if (attendance.isNotEmpty) {
          final presentCount = attendance.where((a) => a.status == AttendanceStatus.present).length;
          final totalCount = attendance.length;
          
          if (!dayAttendance.containsKey(dayName)) {
            dayAttendance[dayName] = [];
          }
          dayAttendance[dayName]!.add((presentCount / totalCount * 100).round());
        }
      }

      // Calculate averages for each day
      final averages = <String, double>{};
      dayAttendance.forEach((day, percentages) {
        if (percentages.isNotEmpty) {
          averages[day] = percentages.reduce((a, b) => a + b) / percentages.length;
        }
      });

      setState(() {
        _dayAttendance = averages;
      });
    } catch (e) {
      debugPrint('Error loading day attendance: $e');
    }
  }

  Future<void> _loadSubjectAverages() async {
    if (_classId == null || _teacher == null) return;
    try {
      final subjects = _teacher!.subjects ?? [];
      final subjectTotals = <String, List<double>>{};

      for (var subject in subjects) {
        // Get all marks for this class and subject
        final marksSnapshot = await _firestore
            .collection('marks')
            .where('classId', isEqualTo: _classId!)
            .where('subjectName', isEqualTo: subject)
            .get();

        final marks = marksSnapshot.docs
            .map((doc) => MarksModel.fromDocument(doc))
            .toList();

        if (marks.isNotEmpty) {
          final percentages = marks.map((m) => m.percentage).toList();
          subjectTotals[subject] = percentages;
        }
      }

      // Calculate averages
      final averages = <String, double>{};
      subjectTotals.forEach((subject, percentages) {
        if (percentages.isNotEmpty) {
          averages[subject] = percentages.reduce((a, b) => a + b) / percentages.length;
        }
      });

      setState(() {
        _subjectAverages = averages;
      });
    } catch (e) {
      debugPrint('Error loading subject averages: $e');
    }
  }

  Future<void> _loadPerformanceDistribution() async {
    if (_classId == null) return;
    try {
      final marksSnapshot = await _firestore
          .collection('marks')
          .where('classId', isEqualTo: _classId!)
          .get();

      final allMarks = marksSnapshot.docs
          .map((doc) => MarksModel.fromDocument(doc))
          .toList();

      // Group by student and calculate average
      final studentAverages = <String, List<double>>{};
      for (var mark in allMarks) {
        if (!studentAverages.containsKey(mark.studentId)) {
          studentAverages[mark.studentId] = [];
        }
        studentAverages[mark.studentId]!.add(mark.percentage);
      }

      // Calculate distribution
      int excellent = 0, good = 0, average = 0, belowAverage = 0;

      studentAverages.forEach((studentId, percentages) {
        if (percentages.isNotEmpty) {
          final avg = percentages.reduce((a, b) => a + b) / percentages.length;
          if (avg >= 80) {
            excellent++;
          } else if (avg >= 60) {
            good++;
          } else if (avg >= 40) {
            average++;
          } else {
            belowAverage++;
          }
        }
      });

      setState(() {
        _performanceDistribution = {
          'Excellent': excellent,
          'Good': good,
          'Average': average,
          'Below Average': belowAverage,
        };
      });
    } catch (e) {
      debugPrint('Error loading performance distribution: $e');
    }
  }

  Future<void> _loadHomeworkSubmissionRate() async {
    if (_classId == null) return;
    try {
      final homework = await _homeworkService.getTeacherHomework().first;
      final classHomework = homework.where((hw) => hw.classId == _classId).toList();
      
      if (classHomework.isEmpty) {
        setState(() => _homeworkSubmissionRate = 0.0);
        return;
      }

      int totalSubmissions = 0;
      int totalExpected = classHomework.length * _students.length;

      for (var hw in classHomework) {
        final submissions = await _homeworkService.getHomeworkSubmissions(hw.homeworkId).first;
        totalSubmissions += submissions.length;
      }

      setState(() {
        _homeworkSubmissionRate = totalExpected > 0 ? (totalSubmissions / totalExpected) : 0.0;
      });
    } catch (e) {
      debugPrint('Error loading homework submission rate: $e');
    }
  }

  Future<void> _loadOverallAttendance() async {
    if (_classId == null) return;
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      int totalPresent = 0;
      int totalDays = 0;

      // Get attendance for last 30 days
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        if (date.weekday > 5) continue; // Skip weekends

        final attendance = await _attendanceService
            .getAttendanceByDateAndClass(classId: _classId!, date: date)
            .first;

        if (attendance.isNotEmpty) {
          totalPresent += attendance.where((a) => a.status == AttendanceStatus.present).length;
          totalDays += attendance.length;
        }
      }

      setState(() {
        _overallAttendance = totalDays > 0 ? (totalPresent / totalDays * 100) : 0.0;
      });
    } catch (e) {
      debugPrint('Error loading overall attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Class Performance", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Class Performance", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only class teachers can view analytics for their assigned class.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text("Class Performance - $_className", style: const TextStyle(color: Colors.black)),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Students',
                          '${_students.length}',
                          Icons.people,
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                        _buildStatItem(
                          'Attendance',
                          '${_overallAttendance.toStringAsFixed(1)}%',
                          Icons.check_circle,
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                        _buildStatItem(
                          'Homework',
                          '${(_homeworkSubmissionRate * 100).toStringAsFixed(0)}%',
                          Icons.assignment,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Overall Attendance by Day
              const Text("Overall Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (_dayAttendance.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "No attendance data available",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day) {
                  final pct = _dayAttendance[day] ?? 0.0;
                  return _buildBarChart(day, pct / 100);
                }),

              const SizedBox(height: 30),

              // Subject Averages
              const Text("Subject Averages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (_subjectAverages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "No marks data available",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                ..._subjectAverages.entries.map((entry) {
                  final color = _getColorForPercentage(entry.value);
                  return _buildProgressCard(entry.key, entry.value / 100, color);
                }),

              const SizedBox(height: 30),

              // Performance Distribution
              const Text("Performance Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDistributionItem('Excellent (≥80%)', _performanceDistribution['Excellent'] ?? 0, Colors.green),
                    _buildDistributionItem('Good (60-79%)', _performanceDistribution['Good'] ?? 0, Colors.blue),
                    _buildDistributionItem('Average (40-59%)', _performanceDistribution['Average'] ?? 0, Colors.orange),
                    _buildDistributionItem('Below Average (<40%)', _performanceDistribution['Below Average'] ?? 0, Colors.red),
                  ],
                ),
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

  Widget _buildBarChart(String day, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${(pct * 100).toInt()}%",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String subject, double val, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${(val * 100).toInt()}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: val,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int count, Color color) {
    final total = _performanceDistribution.values.reduce((a, b) => a + b);
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      default: return '';
    }
  }
}
