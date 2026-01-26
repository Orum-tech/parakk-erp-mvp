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
      // 1. Get subject teachers (teachers who have this class in their classIds list)
      final subjectTeachersFuture = _firestore
          .collection('users')
          // whereIn doesn't support array-contains properly in all combinations, 
          // usually separate queries are safer or just target 'Teacher' if we are confident in data consistency
          // But to be safe on role case: we'll do two queries or rely on one if we fixed creation.
          // Since we fixed creation to be Enum based, it should be likely consistent, but let's be safe.
          .where('role', whereIn: ['Teacher', 'teacher'])
          .where('classIds', arrayContains: classId)
          .get();

      // 2. Get class teacher (explicitly assigned as class teacher for this class)
      final classTeacherFuture = _firestore
          .collection('users')
          .where('role', whereIn: ['Teacher', 'teacher'])
          .where('classTeacherClassId', isEqualTo: classId)
          .get();

      final results = await Future.wait([subjectTeachersFuture, classTeacherFuture]);
      
      final Map<String, TeacherModel> uniqueTeachers = {};

      // Process Subject Teachers
      for (var doc in results[0].docs) {
        try {
          final teacher = TeacherModel.fromDocument(doc);
          uniqueTeachers[teacher.uid] = teacher;
        } catch (e) {
          // skip invalid docs
        }
      }

      // Process Class Teacher
      for (var doc in results[1].docs) {
         try {
          final teacher = TeacherModel.fromDocument(doc);
          uniqueTeachers[teacher.uid] = teacher;
        } catch (e) {
          // skip invalid docs
        }
      }

      final teachers = uniqueTeachers.values.toList();
      
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
