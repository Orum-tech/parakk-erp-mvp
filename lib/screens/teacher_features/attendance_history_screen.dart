import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/teacher_model.dart';
import '../../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TeacherModel? _teacher;
  String? _classId;
  String? _className;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        final teacher = TeacherModel.fromDocument(teacherDoc);
        setState(() {
          _teacher = teacher;
          _classId = teacher.classTeacherClassId;
        });

        // Get class name
        if (_classId != null) {
          final classDoc = await _firestore.collection('classes').doc(_classId).get();
          if (classDoc.exists) {
            setState(() {
              _className = classDoc.data()?['name'] ?? 'Unknown Class';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<AttendanceModel>> _groupByMonth(List<AttendanceModel> attendance) {
    final Map<String, List<AttendanceModel>> grouped = {};
    
    for (var record in attendance) {
      final monthKey = DateFormat('MMMM yyyy').format(record.date);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(record);
    }

    // Sort each month's records by date descending
    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });

    return grouped;
  }

  Map<String, int> _calculateDailyStats(List<AttendanceModel> dailyAttendance) {
    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;
    int holiday = 0;

    for (var record in dailyAttendance) {
      switch (record.status) {
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

    final total = present + absent + late + excused;
    final percentage = total > 0 ? ((present + excused) / total * 100).round() : 0;

    return {
      'present': present,
      'absent': absent,
      'late': late,
      'excused': excused,
      'holiday': holiday,
      'total': total,
      'percentage': percentage,
    };
  }

  Color _getStatusColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Attendance Register", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_classId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Attendance Register", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No class assigned',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to be assigned as a class teacher to view attendance history',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Attendance Register", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            if (_className != null)
              Text(
                _className!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: _firestore
            .collection('attendance')
            .where('classId', isEqualTo: _classId)
            .orderBy('date', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromDocument(doc))
                .toList()),
        builder: (context, allSnapshot) {
          if (allSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading attendance: ${allSnapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final allAttendance = allSnapshot.data ?? [];

              if (allAttendance.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attendance records will appear here once marked',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Group by month and then by unique dates
              final grouped = _groupByMonth(allAttendance);
              final sortedMonths = grouped.keys.toList()
                ..sort((a, b) {
                  final dateA = DateFormat('MMMM yyyy').parse(a);
                  final dateB = DateFormat('MMMM yyyy').parse(b);
                  return dateB.compareTo(dateA);
                });

              // Get unique dates per month
              final Map<String, Set<DateTime>> uniqueDatesByMonth = {};
              for (var month in sortedMonths) {
                uniqueDatesByMonth[month] = grouped[month]!
                    .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
                    .toSet();
              }

              final List<Widget> widgets = [];
              for (var month in sortedMonths) {
                widgets.add(_buildMonthHeader(month));
                final dates = uniqueDatesByMonth[month]!.toList()
                  ..sort((a, b) => b.compareTo(a));
                for (var date in dates) {
                  // Get all attendance for this date
                  final dailyAttendance = allAttendance
                      .where((a) =>
                          a.date.year == date.year &&
                          a.date.month == date.month &&
                          a.date.day == date.day)
                      .toList();
                  final stats = _calculateDailyStats(dailyAttendance);
                  final isHoliday = stats['holiday']! > 0 && stats['total']! == stats['holiday']!;

                  widgets.add(_buildRecordTile(
                    date,
                    stats['percentage']!,
                    isHoliday,
                    _getStatusColor(stats['percentage']!),
                  ));
                }
                widgets.add(const SizedBox(height: 20));
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: widgets,
              );
        },
      ),
    );
  }

  Widget _buildMonthHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildRecordTile(DateTime date, int percentage, bool isHoliday, Color color) {
    final dateFormat = DateFormat('dd MMM');
    final dayFormat = DateFormat('EEE');
    final dateStr = dateFormat.format(date);
    final dayStr = dayFormat.format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(dayStr, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Text(
                isHoliday ? 'Holiday' : '$percentage% Present',
                style: TextStyle(fontWeight: FontWeight.bold, color: isHoliday ? Colors.grey : color),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}