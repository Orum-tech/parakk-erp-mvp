import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/marks_service.dart';
import '../../services/attendance_service.dart';
import '../../models/marks_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';

class AcademicReportsScreen extends StatefulWidget {
  const AcademicReportsScreen({super.key});

  @override
  State<AcademicReportsScreen> createState() => _AcademicReportsScreenState();
}

class _AcademicReportsScreenState extends State<AcademicReportsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MarksService _marksService = MarksService();
  final AttendanceService _attendanceService = AttendanceService();

  StudentModel? _student;
  List<MarksModel> _allMarks = [];
  List<AttendanceModel> _allAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      // Load marks
      _marksService.getStudentMarks(user.uid).listen((marks) {
        if (mounted) {
          setState(() {
            _allMarks = marks;
          });
        }
      });

      // Load attendance
      if (_student?.classId != null) {
        _attendanceService.getStudentAttendance(
          studentId: user.uid,
        ).listen((attendance) {
          if (mounted) {
            setState(() {
              _allAttendance = attendance;
              _isLoading = false;
            });
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Group marks by exam
  Map<String, List<MarksModel>> get _marksByExam {
    final Map<String, List<MarksModel>> grouped = {};
    for (var mark in _allMarks) {
      if (!grouped.containsKey(mark.examId)) {
        grouped[mark.examId] = [];
      }
      grouped[mark.examId]!.add(mark);
    }
    return grouped;
  }

  // Get exam report cards
  List<Map<String, dynamic>> get _examReports {
    final reports = <Map<String, dynamic>>[];
    
    for (var entry in _marksByExam.entries) {
      final examId = entry.key;
      final marks = entry.value;
      if (marks.isEmpty) continue;

      final firstMark = marks.first;
      final examName = firstMark.examName;
      final examDate = firstMark.examDate ?? firstMark.createdAt.toDate();
      
      // Calculate overall percentage for this exam
      double totalObtained = 0;
      int totalMax = 0;
      for (var mark in marks) {
        totalObtained += mark.marksObtained;
        totalMax += mark.maxMarks;
      }
      final overallPercentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
      
      // Calculate CGPA
      double totalPoints = 0;
      for (var mark in marks) {
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
      }
      final cgpa = marks.isNotEmpty ? totalPoints / marks.length : 0.0;
      
      // Determine grade
      String overallGrade;
      Color gradeColor;
      if (cgpa >= 9.0) {
        overallGrade = 'A+ Grade';
        gradeColor = Colors.green;
      } else if (cgpa >= 8.0) {
        overallGrade = 'A Grade';
        gradeColor = Colors.blue;
      } else if (cgpa >= 7.0) {
        overallGrade = 'B+ Grade';
        gradeColor = Colors.orange;
      } else if (cgpa >= 6.0) {
        overallGrade = 'B Grade';
        gradeColor = Colors.orange;
      } else if (cgpa >= 5.0) {
        overallGrade = 'C+ Grade';
        gradeColor = Colors.purple;
      } else if (cgpa >= 4.0) {
        overallGrade = 'C Grade';
        gradeColor = Colors.purple;
      } else {
        overallGrade = 'F Grade';
        gradeColor = Colors.red;
      }

      reports.add({
        'examId': examId,
        'title': examName,
        'subtitle': 'Issued: ${DateFormat('dd MMM yyyy').format(examDate)}',
        'grade': overallGrade,
        'color': gradeColor,
        'marks': marks,
        'cgpa': cgpa,
        'percentage': overallPercentage,
      });
    }

    // Sort by date (most recent first)
    reports.sort((a, b) {
      final dateA = (a['marks'] as List<MarksModel>).first.examDate ?? 
                   (a['marks'] as List<MarksModel>).first.createdAt.toDate();
      final dateB = (b['marks'] as List<MarksModel>).first.examDate ?? 
                   (b['marks'] as List<MarksModel>).first.createdAt.toDate();
      return dateB.compareTo(dateA);
    });

    return reports;
  }

  // Calculate attendance summary
  Map<String, dynamic> get _attendanceSummary {
    if (_allAttendance.isEmpty) {
      return {
        'percentage': 0.0,
        'present': 0,
        'absent': 0,
        'late': 0,
        'total': 0,
      };
    }

    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;
    int holiday = 0;

    for (var attendance in _allAttendance) {
      switch (attendance.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.excused:
          excused++;
          break;
        case AttendanceStatus.holiday:
          holiday++;
          break;
      }
    }

    // Total excludes holidays (not school days)
    // Excused absences are counted as present for attendance percentage
    final total = present + absent + late + excused;
    final percentage = total > 0 ? ((present + late + excused) / total) * 100 : 0.0;

    return {
      'percentage': percentage,
      'present': present,
      'absent': absent,
      'late': late,
      'excused': excused,
      'holiday': holiday,
      'total': total,
    };
  }

  // Calculate overall performance
  Map<String, dynamic> get _overallPerformance {
    if (_allMarks.isEmpty) {
      return {
        'cgpa': 0.0,
        'averagePercentage': 0.0,
        'totalSubjects': 0,
        'grade': 'N/A',
      };
    }

    double totalPoints = 0;
    double totalPercentage = 0;
    final uniqueSubjects = <String>{};

    for (var mark in _allMarks) {
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
      totalPercentage += mark.percentage;
      uniqueSubjects.add(mark.subjectId);
    }

    final avgCGPA = _allMarks.isNotEmpty ? totalPoints / _allMarks.length : 0.0;
    final avgPercentage = _allMarks.isNotEmpty ? totalPercentage / _allMarks.length : 0.0;

    String overallGrade;
    if (avgCGPA >= 9.0) {
      overallGrade = 'A+ (Excellent)';
    } else if (avgCGPA >= 8.0) {
      overallGrade = 'A (Very Good)';
    } else if (avgCGPA >= 7.0) {
      overallGrade = 'B+ (Good)';
    } else if (avgCGPA >= 6.0) {
      overallGrade = 'B (Satisfactory)';
    } else if (avgCGPA >= 5.0) {
      overallGrade = 'C+ (Average)';
    } else if (avgCGPA >= 4.0) {
      overallGrade = 'C (Below Average)';
    } else {
      overallGrade = 'F (Fail)';
    }

    return {
      'cgpa': avgCGPA,
      'averagePercentage': avgPercentage,
      'totalSubjects': uniqueSubjects.length,
      'grade': overallGrade,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Academic Reports", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final examReports = _examReports;
    final attendanceSummary = _attendanceSummary;
    final overallPerformance = _overallPerformance;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Academic Reports", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Overall Performance Card
            if (_allMarks.isNotEmpty)
              _buildPerformanceCard(overallPerformance),
            
            // Attendance Summary
            if (_allAttendance.isNotEmpty)
              _buildAttendanceCard(attendanceSummary),

            // Exam Reports
            if (examReports.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No exam reports available yet",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...examReports.map((report) => _buildReportCard(
                report['title'] as String,
                report['subtitle'] as String,
                report['grade'] as String,
                report['color'] as Color,
                report['marks'] as List<MarksModel>,
                report['cgpa'] as double,
                report['percentage'] as double,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> performance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF1565C0).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overall Performance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPerformanceMetric(
                "CGPA",
                performance['cgpa'].toStringAsFixed(2),
                Icons.star,
              ),
              _buildPerformanceMetric(
                "Average",
                "${performance['averagePercentage'].toStringAsFixed(1)}%",
                Icons.percent,
              ),
              _buildPerformanceMetric(
                "Subjects",
                "${performance['totalSubjects']}",
                Icons.menu_book,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  performance['grade'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
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
        const SizedBox(height: 4),
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

  Widget _buildAttendanceCard(Map<String, dynamic> summary) {
    final percentage = summary['percentage'] as double;
    Color color;
    if (percentage >= 90) {
      color = Colors.green;
    } else if (percentage >= 75) {
      color = Colors.blue;
    } else if (percentage >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return _buildReportCard(
      "Attendance Summary",
      "Academic Year ${DateTime.now().year}-${DateTime.now().year + 1}",
      "${percentage.toStringAsFixed(1)}%",
      color,
      null,
      0.0,
      percentage,
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    String grade,
    Color color,
    List<MarksModel>? marks,
    double cgpa,
    double percentage,
  ) {
    return GestureDetector(
      onTap: marks != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ReportDetailScreen(
                    title: title,
                    subtitle: subtitle,
                    marks: marks,
                    cgpa: cgpa,
                    percentage: percentage,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                grade,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Report Detail Screen
class ReportDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<MarksModel> marks;
  final double cgpa;
  final double percentage;

  const ReportDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.marks,
    required this.cgpa,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard("CGPA", cgpa.toStringAsFixed(2), Icons.star),
                    _buildStatCard("Overall", "${percentage.toStringAsFixed(1)}%", Icons.percent),
                    _buildStatCard("Subjects", "${marks.length}", Icons.menu_book),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Subject-wise marks
          const Text(
            "Subject-wise Performance",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ...marks.map((mark) => _buildSubjectCard(mark)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(MarksModel mark) {
    final grade = mark.grade ?? mark.calculateGrade();
    final percentage = mark.percentage;
    
    Color gradeColor;
    if (percentage >= 90) {
      gradeColor = Colors.green;
    } else if (percentage >= 80) {
      gradeColor = Colors.blue;
    } else if (percentage >= 70) {
      gradeColor = Colors.orange;
    } else if (percentage >= 60) {
      gradeColor = Colors.purple;
    } else {
      gradeColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: gradeColor, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mark.subjectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${mark.marksObtained} / ${mark.maxMarks}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
