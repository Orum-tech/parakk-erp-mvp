import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/parent_service.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';

class ChildAttendanceScreen extends StatefulWidget {
  final StudentModel child;

  const ChildAttendanceScreen({super.key, required this.child});

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  final ParentService _parentService = ParentService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _parentService.getChildAttendanceStats(widget.child.uid);
      setState(() => _stats = stats);
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
      await _loadAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Text("${widget.child.name}'s Attendance", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final percentage = _stats?['percentage'] ?? 0.0;
    final present = _stats?['present'] ?? 0;
    final absent = _stats?['absent'] ?? 0;
    final late = _stats?['late'] ?? 0;
    final excused = _stats?['excused'] ?? 0;
    final total = _stats?['total'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("${widget.child.name}'s Attendance", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
            // Hero Circular Indicator
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
                        const SizedBox(height: 10),
                        Text("${percentage.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text("${widget.child.className ?? 'N/A'} • ${widget.child.rollNumber ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Text("$total", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Present", present.toString(), Icons.check_circle, Colors.green),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard("Absent", absent.toString(), Icons.cancel, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Late", late.toString(), Icons.schedule, Colors.orange),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard("Excused", excused.toString(), Icons.info, Colors.blue),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Attendance History
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Recent Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),

            StreamBuilder<List<AttendanceModel>>(
              stream: _parentService.getChildAttendance(
                studentId: widget.child.uid,
                startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
                endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final attendanceList = snapshot.data ?? [];

                if (attendanceList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No attendance records found', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    return _buildAttendanceTile(attendance);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(AttendanceModel attendance) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (attendance.status) {
      case AttendanceStatus.present:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Present';
        break;
      case AttendanceStatus.absent:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      case AttendanceStatus.late:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Late';
        break;
      case AttendanceStatus.excused:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        statusText = 'Excused';
        break;
      case AttendanceStatus.holiday:
        statusColor = Colors.purple;
        statusIcon = Icons.beach_access;
        statusText = 'Holiday';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(attendance.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  attendance.subjectName ?? attendance.className,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (attendance.remark != null && attendance.remark!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    attendance.remark!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
