import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marks_model.dart';
import '../models/exam_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';

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
      for (var classId in classIds) {
        final classDoc = await _firestore.collection('classes').doc(classId).get();
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
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
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
      // Fallback to lowercase 'student'
      try {
        final studentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: classId)
            .get();

        final students = studentsSnapshot.docs
            .map((doc) => StudentModel.fromDocument(doc))
            .toList();

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
      } catch (e2) {
        throw Exception('Failed to fetch students: $e. Fallback also failed: $e2');
      }
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
    } catch (e) {
      throw Exception('Failed to save marks: $e');
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
