import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StudentModel? _student;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

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

      // Get attendance stats
      if (_student != null) {
        final stats = await _attendanceService.getStudentAttendanceStats(_student!.uid);
        setState(() => _stats = stats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      await _loadStudentData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Attendance Insights", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final percentage = _stats?['percentage'] ?? 0.0;
    final present = _stats?['present'] ?? 0;
    final absent = _stats?['absent'] ?? 0;
    final late = _stats?['late'] ?? 0;
    final total = _stats?['total'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Attendance Insights", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Select Month',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Hero Circular Indicator
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: percentage >= 75
                      ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
                      : percentage >= 50
                          ? [Colors.orange, Colors.orangeAccent]
                          : [Colors.red, Colors.redAccent],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Overall Attendance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(
                          "${percentage.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            percentage >= 75
                                ? "Excellent Pace 🚀"
                                : percentage >= 50
                                    ? "Good Progress 📈"
                                    : "Needs Improvement ⚠️",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.check_circle_outline, color: Colors.white24, size: 100),
                        ),
                        Center(
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. Stats Grid
            Row(
              children: [
                _buildStatCard("Total Days", total.toString(), Colors.blue),
                const SizedBox(width: 15),
                _buildStatCard("Present", present.toString(), Colors.green),
                const SizedBox(width: 15),
                _buildStatCard("Absent", absent.toString(), Colors.redAccent),
              ],
            ),
            if (late > 0) ...[
              const SizedBox(height: 15),
              _buildStatCard("Late", late.toString(), Colors.orange),
            ],

            const SizedBox(height: 30),

            // 3. Recent Attendance List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.calendar_month_rounded, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 15),

            // 4. Daily List
            if (_student != null)
              StreamBuilder<List<AttendanceModel>>(
                stream: _attendanceService.getStudentAttendance(studentId: _student!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint('Attendance stream error: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading attendance',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStudentData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final attendanceList = snapshot.data ?? [];
                  debugPrint('Total attendance records fetched: ${attendanceList.length}');
                  
                  final filteredList = attendanceList
                      .where((a) =>
                          a.date.year == _selectedMonth.year &&
                          a.date.month == _selectedMonth.month)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  debugPrint('Filtered attendance records for ${_selectedMonth.month}/${_selectedMonth.year}: ${filteredList.length}');

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records for this month',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            if (attendanceList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Total records: ${attendanceList.length}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredList.take(30).map((attendance) {
                      return _buildDayTile(
                        attendance.date,
                        attendance.status,
                        attendance.remark,
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(DateTime date, AttendanceStatus status, String? remark) {
    final dateStr = "${date.day} ${_getMonthAbbreviation(date.month)}";
    final dayStr = _getDayAbbreviation(date.weekday);
    final statusStr = AttendanceModel.statusToString(status);
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(dayStr, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusStr,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (remark != null && remark.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  remark,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.redAccent;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
      case AttendanceStatus.holiday:
        return Colors.purple;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
