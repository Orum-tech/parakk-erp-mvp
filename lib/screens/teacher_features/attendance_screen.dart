import 'package:flutter/material.dart';
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
  
  String? _classId;
  String? _className;
  List<StudentModel> _students = [];
  final Map<String, AttendanceStatus> _studentAttendance = {};
  final Map<String, String> _remarks = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingStudents = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadClassAndStudents();
  }

  Future<void> _loadClassAndStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      // Get class teacher's class
      final classId = await _attendanceService.getClassTeacherClassId();
      
      if (classId == null) {
        setState(() {
          _hasPermission = false;
          _isLoadingStudents = false;
        });
        return;
      }

      // Verify permission
      final hasPermission = await _attendanceService.isClassTeacherForClass(classId);
      if (!hasPermission) {
        setState(() {
          _hasPermission = false;
          _isLoadingStudents = false;
        });
        return;
      }

      setState(() {
        _classId = classId;
        _hasPermission = true;
      });

      // Parse className from classId (format: class_5_A)
      final parts = classId.replaceFirst('class_', '').split('_');
      if (parts.length == 2) {
        setState(() {
          _className = 'Class ${parts[0]}-${parts[1]}';
        });
      }

      // Load students
      final students = await _attendanceService.getStudentsByClass(classId);
      
      if (students.isEmpty) {
        setState(() {
          _isLoadingStudents = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students found in this class. Please ensure students are assigned to this class.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      // Load existing attendance for today
      final todayAttendance = await _attendanceService
          .getAttendanceByDateAndClass(classId: classId, date: _selectedDate)
          .first;

      setState(() {
        _students = students;
        // Initialize attendance status
        for (var student in students) {
          final existing = todayAttendance.firstWhere(
            (a) => a.studentId == student.uid,
            orElse: () => AttendanceModel(
              attendanceId: '',
              studentId: student.uid,
              studentName: student.name,
              classId: classId,
              className: _className ?? '',
              date: _selectedDate,
              status: AttendanceStatus.present,
              createdAt: Timestamp.now(),
            ),
          );
          _studentAttendance[student.uid] = existing.status;
        }
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadClassAndStudents();
    }
  }

  Future<void> _submitAttendance() async {
    if (_classId == null || _className == null) return;

    setState(() => _isLoading = true);
    try {
      await _attendanceService.markAttendance(
        classId: _classId!,
        className: _className!,
        date: _selectedDate,
        studentAttendance: _studentAttendance,
        remarks: _remarks.isNotEmpty ? _remarks : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _presentCount => _studentAttendance.values.where((s) => s == AttendanceStatus.present).length;
  int get _absentCount => _studentAttendance.values.where((s) => s == AttendanceStatus.absent).length;
  int get _lateCount => _studentAttendance.values.where((s) => s == AttendanceStatus.late).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStudents) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("Mark Attendance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission || _classId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("Mark Attendance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only class teachers can mark attendance for their assigned class.',
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
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mark Attendance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text(
              "$_className • ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge("Present", _presentCount.toString(), Colors.green),
                _buildStatBadge("Absent", _absentCount.toString(), Colors.red),
                _buildStatBadge("Late", _lateCount.toString(), Colors.orange),
                _buildStatBadge("Total", _students.length.toString(), Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Student List
          Expanded(
            child: _students.isEmpty
                ? Center(
                    child: Text(
                      'No students found in this class',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final status = _studentAttendance[student.uid] ?? AttendanceStatus.present;
                      final isPresent = status == AttendanceStatus.present;
                      final isAbsent = status == AttendanceStatus.absent;
                      final isLate = status == AttendanceStatus.late;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAbsent ? Colors.red.withOpacity(0.3) : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            child: Text(
                              student.rollNumber ?? '${index + 1}',
                              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: _remarks[student.uid] != null
                              ? Text(_remarks[student.uid]!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusBtn("P", isPresent, Colors.green, () {
                                setState(() => _studentAttendance[student.uid] = AttendanceStatus.present);
                              }),
                              const SizedBox(width: 6),
                              _buildStatusBtn("L", isLate, Colors.orange, () {
                                setState(() => _studentAttendance[student.uid] = AttendanceStatus.late);
                              }),
                              const SizedBox(width: 6),
                              _buildStatusBtn("A", isAbsent, Colors.red, () {
                                setState(() => _studentAttendance[student.uid] = AttendanceStatus.absent);
                              }),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.note_add, size: 18),
                                color: Colors.grey[600],
                                onPressed: () => _showRemarkDialog(student),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("Submit Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusBtn(String label, bool isActive, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _showRemarkDialog(StudentModel student) async {
    final remarkController = TextEditingController(text: _remarks[student.uid]);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Remark for ${student.name}'),
        content: TextField(
          controller: remarkController,
          decoration: const InputDecoration(
            hintText: 'Enter remark (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (remarkController.text.trim().isEmpty) {
                  _remarks.remove(student.uid);
                } else {
                  _remarks[student.uid] = remarkController.text.trim();
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
