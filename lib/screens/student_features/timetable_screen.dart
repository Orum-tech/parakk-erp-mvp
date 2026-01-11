import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/timetable_service.dart';
import '../../models/timetable_model.dart';
import '../../models/student_model.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StudentModel? _student;
  bool _isLoading = true;
  
  final List<DayOfWeek> _days = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
    DayOfWeek.saturday,
  ];

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
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Weekly Schedule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null || _student!.classId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Weekly Schedule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('No class assigned. Please contact your administrator.'),
        ),
      );
    }

    final today = DateTime.now();
    final currentDayIndex = today.weekday - 1; // Monday = 0, Sunday = 6
    // Clamp to valid range (0-5) since we only have 6 days (Mon-Sat)
    final safeDayIndex = currentDayIndex < _days.length ? currentDayIndex : 0;
    final initialTab = safeDayIndex;

    return DefaultTabController(
      initialIndex: initialTab,
      length: _days.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weekly Schedule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              if (_student?.className != null)
                Text(
                  _student!.className!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1565C0),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: _days.map((day) => Tab(text: _getDayAbbreviation(day))).toList(),
          ),
        ),
        body: TabBarView(
          children: _days.map((day) => _buildDayList(day, day == _days[safeDayIndex])).toList(),
        ),
      ),
    );
  }

  Widget _buildDayList(DayOfWeek day, bool isActiveDay) {
    if (_student?.classId == null) {
      return const Center(child: Text('No class assigned'));
    }

    return StreamBuilder<List<TimetableModel>>(
      stream: _timetableService.getStudentTimetable(_student!.classId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allEntries = snapshot.data ?? [];
        final dayEntries = allEntries
            .where((entry) => entry.day == day)
            .toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

        if (dayEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No schedule for ${_getDayName(day)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (isActiveDay)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Today's Classes",
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ),
            ...dayEntries.map((entry) => _buildClassCard(entry, isActiveDay)),
          ],
        );
      },
    );
  }

  Widget _buildClassCard(TimetableModel entry, bool isLive) {
    final startTime = _formatTime(entry.startTime);
    final endTime = _formatTime(entry.endTime);
    final color = _getSubjectColor(entry.subjectName);
    final isBreak = entry.isBreak;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                height: 40,
                width: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 5),
              ),
              Text(endTime, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLive ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isLive ? Border.all(color: Colors.blue, width: 1.5) : null,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isBreak ? entry.breakType ?? 'Break' : entry.subjectName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isBreak ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      if (isLive && !isBreak)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "LIVE",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  if (!isBreak) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Period ${entry.periodNumber}",
                          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(Icons.person, size: 12, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.teacherName,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                        if (entry.room != null) ...[
                          const Icon(Icons.room, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            entry.room!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String _getDayAbbreviation(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[subject.hashCode % colors.length];
  }
}
