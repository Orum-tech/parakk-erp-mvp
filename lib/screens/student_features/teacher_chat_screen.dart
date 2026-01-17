import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_service.dart';
import '../../models/student_model.dart';
import 'chat_detail_screen.dart';

class TeacherChatScreen extends StatefulWidget {
  const TeacherChatScreen({super.key});

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final StudentService _studentService = StudentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentModel? _student;
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get student data
      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        final student = StudentModel.fromDocument(studentDoc);
        setState(() => _student = student);

        // Get teachers for student's class
        if (student.classId != null) {
          final teachers = await _studentService.getTeachersWithSubjects(student.classId!);
          setState(() => _teachers = teachers);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teachers: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Ask Teachers", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No teachers available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Teachers will appear here once assigned to your class',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeachers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      final isClassTeacher = teacher['isClassTeacher'] == true;
                      
                      return _buildTeacherCard(
                        teacherName: teacher['teacherName'] ?? 'Unknown',
                        teacherId: teacher['teacherId'] ?? '',
                        subject: teacher['primarySubject'] ?? 'General',
                        email: teacher['email'] ?? '',
                        isClassTeacher: isClassTeacher,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                teacherId: teacher['teacherId'] ?? '',
                                teacherName: teacher['teacherName'] ?? 'Unknown',
                                teacherEmail: teacher['email'],
                                subject: teacher['primarySubject'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildTeacherCard({
    required String teacherName,
    required String teacherId,
    required String subject,
    required String email,
    required bool isClassTeacher,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isClassTeacher
            ? Border.all(color: Colors.green.withOpacity(0.3), width: 1.5)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isClassTeacher ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              child: Text(
                teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                style: TextStyle(
                  color: isClassTeacher ? Colors.green[800] : Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            if (isClassTeacher)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                teacherName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (isClassTeacher)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Class Teacher",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subject,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isClassTeacher ? Colors.green : Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text("Chat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
