import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marks_model.dart';
import '../models/exam_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import 'notification_service.dart';

class MarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get classes where teacher teaches
  Future<List<Map<String, String>>> getTeacherClasses(String teacherId) async {
    try {
      final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      if (!teacherDoc.exists) return [];

      final teacher = TeacherModel.fromDocument(teacherDoc);
      final classIds = teacher.classIds ?? [];

      if (classIds.isEmpty) return [];

      // Fetch class details
      final classes = <Map<String, String>>[];
      
      // Parallel fetch of class documents
      final classFutures = classIds.map((classId) => 
        _firestore.collection('classes').doc(classId).get()
      );
      
      final classDocs = await Future.wait(classFutures);
      
      for (var i = 0; i < classIds.length; i++) {
        final classId = classIds[i];
        final classDoc = classDocs[i];
        
        if (classDoc.exists) {
          final data = classDoc.data()!;
          classes.add({
            'id': classId,
            'name': '${data['className'] ?? ''}-${data['section'] ?? ''}',
            'className': data['className'] ?? '',
            'section': data['section'] ?? '',
          });
        } else {
          // If class document doesn't exist, parse from classId
          final parts = classId.replaceFirst('class_', '').split('_');
          if (parts.length == 2) {
            classes.add({
              'id': classId,
              'name': 'Class ${parts[0]}-${parts[1]}',
              'className': 'Class ${parts[0]}',
              'section': parts[1],
            });
          }
        }
      }

      return classes;
    } catch (e) {
      throw Exception('Failed to fetch teacher classes: $e');
    }
  }

  // Get subjects that teacher teaches
  Future<List<Map<String, String>>> getTeacherSubjects(String teacherId) async {
    try {
      final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      if (!teacherDoc.exists) return [];

      final teacher = TeacherModel.fromDocument(teacherDoc);
      final subjects = teacher.subjects ?? [];

      return subjects.map((subject) => {
        'id': subject,
        'name': subject,
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch teacher subjects: $e');
    }
  }

  // Get students by class
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      // use whereIn to handle both 'Student' and 'student' in a single query
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['Student', 'student'])
          .where('classId', isEqualTo: classId)
          .get();

      final students = studentsSnapshot.docs
          .map((doc) => StudentModel.fromDocument(doc))
          .toList();

      // Sort by rollNumber
      students.sort((a, b) {
        final rollA = a.rollNumber ?? '';
        final rollB = b.rollNumber ?? '';
        final numA = int.tryParse(rollA);
        final numB = int.tryParse(rollB);
        if (numA != null && numB != null) {
          return numA.compareTo(numB);
        }
        return rollA.compareTo(rollB);
      });

      return students;
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  // Create or update exam
  Future<String> createOrUpdateExam({
    String? examId,
    required String examName,
    required ExamType examType,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    required DateTime examDate,
    required int maxMarks,
    int? passingMarks,
    String? instructions,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacher = TeacherModel.fromDocument(teacherDoc);
      final teacherName = teacher.name;

      // Verify teacher teaches this class and subject
      final teachesClass = teacher.classIds?.contains(classId) ?? false;
      final teachesSubject = teacher.subjects?.contains(subjectId) ?? false;

      if (!teachesClass || !teachesSubject) {
        throw Exception('You can only create exams for classes and subjects you teach');
      }

      final exam = ExamModel(
        examId: examId ?? '',
        examName: examName,
        examType: examType,
        classId: classId,
        className: className,
        subjectId: subjectId,
        subjectName: subjectName,
        teacherId: user.uid,
        teacherName: teacherName,
        examDate: examDate,
        maxMarks: maxMarks,
        passingMarks: passingMarks,
        instructions: instructions,
        createdAt: Timestamp.now(),
      );

      if (examId != null && examId.isNotEmpty) {
        await _firestore.collection('exams').doc(examId).update(exam.toMap());
        return examId;
      } else {
        final docRef = await _firestore.collection('exams').add(exam.toMap());
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to save exam: $e');
    }
  }

  // Save marks for multiple students
  Future<void> saveMarks({
    required String examId,
    required String examName,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    required int maxMarks,
    required DateTime examDate,
    required Map<String, int> studentMarks, // studentId -> marks
    Map<String, String>? studentRemarks, // studentId -> remarks
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacher = TeacherModel.fromDocument(teacherDoc);
      final teacherName = teacher.name;

      // Verify teacher teaches this class and subject
      final teachesClass = teacher.classIds?.contains(classId) ?? false;
      final teachesSubject = teacher.subjects?.contains(subjectId) ?? false;

      if (!teachesClass || !teachesSubject) {
        throw Exception('You can only enter marks for classes and subjects you teach');
      }

      // Get student info
      final students = await getStudentsByClass(classId);
      final studentMap = {for (var s in students) s.uid: s};
      // Get schoolId from first student (all students in same class should have same schoolId)
      final schoolId = students.isNotEmpty ? students.first.schoolId : '';

      final batch = _firestore.batch();

      for (var entry in studentMarks.entries) {
        final studentId = entry.key;
        final marksObtained = entry.value;
        final student = studentMap[studentId];

        if (student == null) continue;

        // Create marks document ID
        final marksId = '${examId}_$studentId';
        final marksRef = _firestore.collection('marks').doc(marksId);

        final marks = MarksModel(
          marksId: marksId,
          schoolId: schoolId,
          examId: examId,
          examName: examName,
          studentId: studentId,
          studentName: student.name,
          classId: classId,
          className: className,
          subjectId: subjectId,
          subjectName: subjectName,
          marksObtained: marksObtained,
          maxMarks: maxMarks,
          remarks: studentRemarks?[studentId],
          enteredBy: user.uid,
          enteredByName: teacherName,
          examDate: examDate,
          createdAt: Timestamp.now(),
        );

        batch.set(marksRef, marks.toMap(), SetOptions(merge: true));
      }

      await batch.commit();

      // Create notifications in parallel
      try {
        final notificationService = NotificationService();
        final notificationFutures = studentMarks.keys.map((studentId) => 
          notificationService.notifyMarksEntered(
            studentId: studentId,
            examName: examName,
            subjectName: subjectName,
            examId: examId,
          )
        );
        await Future.wait(notificationFutures);
      } catch (e) {
        // Don't fail marks entry if notification fails
        debugPrint('Error creating notifications: $e');
      }
    } catch (e) {
      throw Exception('Failed to save marks: $e');
    }
  }

  // Get all marks for a specific exam in a class (for rank calculation)
  Future<List<MarksModel>> getExamMarksForClass(String examId, String classId) async {
    try {
      Query query = _firestore
          .collection('marks')
          .where('classId', isEqualTo: classId);

      // If examId is provided, filter by it
      if (examId.isNotEmpty) {
        query = query.where('examId', isEqualTo: examId);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => MarksModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exam marks: $e');
    }
  }

  // Calculate rank for a student in a specific exam
  Future<int> calculateStudentRank(String studentId, String examId, String classId) async {
    try {
      // Get all marks for this exam in the class
      final allMarks = await getExamMarksForClass(examId, classId);

      if (allMarks.isEmpty) return 0;

      // Group marks by student and calculate total percentage
      final Map<String, List<MarksModel>> marksByStudent = {};
      for (var mark in allMarks) {
        if (!marksByStudent.containsKey(mark.studentId)) {
          marksByStudent[mark.studentId] = [];
        }
        marksByStudent[mark.studentId]!.add(mark);
      }

      // Calculate total percentage for each student
      final List<Map<String, dynamic>> studentScores = [];
      for (var entry in marksByStudent.entries) {
        final studentMarks = entry.value;
        double totalMarks = 0;
        double maxTotalMarks = 0;

        for (var mark in studentMarks) {
          totalMarks += mark.marksObtained;
          maxTotalMarks += mark.maxMarks;
        }

        final percentage = maxTotalMarks > 0 ? (totalMarks / maxTotalMarks) * 100 : 0.0;

        studentScores.add({
          'studentId': entry.key,
          'percentage': percentage,
          'totalMarks': totalMarks,
          'maxTotalMarks': maxTotalMarks,
        });
      }

      // Sort by percentage (descending), then by total marks (descending)
      studentScores.sort((a, b) {
        final pctCompare = (b['percentage'] as double).compareTo(a['percentage'] as double);
        if (pctCompare != 0) return pctCompare;
        return (b['totalMarks'] as double).compareTo(a['totalMarks'] as double);
      });

      // Find the rank of the current student
      for (int i = 0; i < studentScores.length; i++) {
        if (studentScores[i]['studentId'] == studentId) {
          return i + 1; // Rank is 1-based
        }
      }

      return 0; // Student not found
    } catch (e) {
      throw Exception('Failed to calculate rank: $e');
    }
  }

  // Get marks for a student
  Stream<List<MarksModel>> getStudentMarks(String studentId) {
    try {
      return _firestore
          .collection('marks')
          .where('studentId', isEqualTo: studentId)
          .orderBy('examDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MarksModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch student marks: $e');
    }
  }

  // Get marks by exam
  Future<List<MarksModel>> getMarksByExam(String examId) async {
    try {
      final snapshot = await _firestore
          .collection('marks')
          .where('examId', isEqualTo: examId)
          .get();

      return snapshot.docs
          .map((doc) => MarksModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch marks: $e');
    }
  }

  // Get exams for a class and subject
  Future<List<ExamModel>> getExamsByClassAndSubject({
    required String classId,
    required String subjectId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('classId', isEqualTo: classId)
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('examDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExamModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exams: $e');
    }
  }
}
