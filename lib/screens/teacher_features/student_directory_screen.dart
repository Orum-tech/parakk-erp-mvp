import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/student_model.dart';
import '../../models/teacher_model.dart';
import '../../services/attendance_service.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TeacherModel? _teacher;
  String? _classId;
  String? _className;
  List<StudentModel> _students = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get teacher data
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

          // Get students
          final students = await _attendanceService.getStudentsByClass(_classId!);
          setState(() {
            _students = students;
          });
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

  Future<void> _callParent(StudentModel student) async {
    String? phoneNumber;

    // Try to get parent phone number from parent's user document
    if (student.parentId != null) {
      try {
        final parentDoc = await _firestore.collection('users').doc(student.parentId).get();
        if (parentDoc.exists) {
          final parentData = parentDoc.data();
          phoneNumber = parentData?['phoneNumber'] as String?;
        }
      } catch (e) {
        debugPrint('Error fetching parent phone: $e');
      }
    }

    // Fallback to emergency contact if parent phone not found
    if ((phoneNumber == null || phoneNumber.isEmpty) && student.emergencyContact != null) {
      phoneNumber = student.emergencyContact;
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.orange),
      );
      return;
    }

    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<StudentModel> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((student) {
      final name = student.name.toLowerCase() ?? '';
      final rollNumber = student.rollNumber?.toLowerCase() ?? '';
      return name.contains(_searchQuery) || rollNumber.contains(_searchQuery);
    }).toList();
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.redAccent,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Student Directory", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          title: const Text("Student Directory", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                'You need to be assigned as a class teacher to view students',
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
            const Text("Student Directory", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name or roll number...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Student Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${_filteredStudents.length} student${_filteredStudents.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          // Student List
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No students found'
                              : 'No students match your search',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final color = _getAvatarColor(index);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Text(
                              (student.name.isNotEmpty ?? false) ? student.name[0].toUpperCase() : '?',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            student.name ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Roll No: ${student.rollNumber ?? 'N/A'} • ${_className ?? 'Unknown Class'}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () => _callParent(student),
                            tooltip: 'Call parent',
                          ),
                          onTap: () {
                            // Future: Open Student Profile
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}