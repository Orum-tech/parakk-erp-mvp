import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teacher_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get class teacher for student's class
  Future<Map<String, String>?> getClassTeacher(String classId) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return null;

      final classData = classDoc.data()!;
      final classTeacherId = classData['classTeacherId'] as String?;
      
      if (classTeacherId == null) return null;

      final teacherDoc = await _firestore.collection('users').doc(classTeacherId).get();
      if (!teacherDoc.exists) return null;

      final teacherData = teacherDoc.data()!;
      return {
        'teacherId': classTeacherId,
        'teacherName': teacherData['name'] ?? '',
        'email': teacherData['email'] ?? '',
        'phoneNumber': teacherData['phoneNumber'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  // Get all teachers who teach the student's class (subject teachers + class teacher)
  Future<List<TeacherModel>> getTeachersForClass(String classId) async {
    try {
      QuerySnapshot teachersSnapshot;
      
      try {
        teachersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'Teacher')
            .get();
      } catch (e) {
        // Fallback to lowercase 'teacher'
        teachersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get();
      }

      final teachers = teachersSnapshot.docs
          .map((doc) {
            try {
              final teacher = TeacherModel.fromDocument(doc);
              
              // Check if teacher teaches this class
              final teachesThisClass = 
                  (teacher.classIds != null && teacher.classIds!.contains(classId)) ||
                  (teacher.classTeacherClassId == classId);
              
              if (teachesThisClass) {
                return teacher;
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .where((teacher) => teacher != null)
          .cast<TeacherModel>()
          .toList();

      // Sort by name
      teachers.sort((a, b) => a.name.compareTo(b.name));

      return teachers;
    } catch (e) {
      return [];
    }
  }

  // Get teachers with their subjects for a class
  Future<List<Map<String, dynamic>>> getTeachersWithSubjects(String classId) async {
    try {
      final teachers = await getTeachersForClass(classId);
      
      return teachers.map((teacher) {
        // Get primary subject (first subject or most relevant)
        final primarySubject = teacher.subjects?.isNotEmpty == true 
            ? teacher.subjects!.first 
            : 'General';
        
        return {
          'teacherId': teacher.uid,
          'teacherName': teacher.name,
          'email': teacher.email,
          'phoneNumber': teacher.phoneNumber,
          'subjects': teacher.subjects ?? [],
          'primarySubject': primarySubject,
          'isClassTeacher': teacher.classTeacherClassId == classId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
