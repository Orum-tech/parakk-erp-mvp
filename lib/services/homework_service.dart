import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/homework_model.dart';
import '../models/homework_submission_model.dart';
import 'notification_service.dart';
import 'attendance_service.dart';

class HomeworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // Create homework (Teacher)
  Future<String> createHomework({
    required String title,
    String? description,
    required String classId,
    required String className,
    required String section,
    required String subjectId,
    required String subjectName,
    required DateTime dueDate,
    List<String>? attachmentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher info from Firestore
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');

      final teacherData = teacherDoc.data()!;
      final fullClassName = '$className-$section';

      final homework = HomeworkModel(
        homeworkId: '', // Will be set by Firestore
        title: title,
        description: description,
        classId: classId,
        className: fullClassName,
        subjectId: subjectId,
        subjectName: subjectName,
        teacherId: user.uid,
        teacherName: teacherData['name'] ?? '',
        dueDate: dueDate,
        attachmentUrls: attachmentUrls,
        totalStudents: 0, // Will be updated later
        submittedCount: 0,
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore.collection('homework').add(homework.toMap());
      
      // Update with generated ID
      await docRef.update({'homeworkId': docRef.id});

      // Get all students in the class and create notifications
      try {
        final attendanceService = AttendanceService();
        final students = await attendanceService.getStudentsByClass(classId);
        final studentIds = students.map((s) => s.uid).toList();
        
        if (studentIds.isNotEmpty) {
          final notificationService = NotificationService();
          await notificationService.notifyHomeworkAssigned(
            studentIds: studentIds,
            homeworkTitle: title,
            homeworkId: docRef.id,
            dueDate: dueDate,
          );
        }
      } catch (e) {
        // Don't fail homework creation if notification fails
        debugPrint('Error creating notifications: $e');
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create homework: $e');
    }
  }

  // Get homework for teacher (all homework created by teacher)
  Stream<List<HomeworkModel>> getTeacherHomework() {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.value([]);

      return _firestore
          .collection('homework')
          .where('teacherId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => HomeworkModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Get homework for student (homework assigned to student's class)
  Stream<List<HomeworkModel>> getStudentHomework(String studentClassId) {
    try {
      return _firestore
          .collection('homework')
          .where('classId', isEqualTo: studentClassId)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => HomeworkModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Submit homework (Student)
  Future<String> submitHomework({
    required String homeworkId,
    String? submissionText,
    List<String>? attachmentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get student info
      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!studentDoc.exists) throw Exception('Student data not found');

      final studentData = studentDoc.data()!;
      
      // Get homework to check due date
      final homeworkDoc = await _firestore.collection('homework').doc(homeworkId).get();
      if (!homeworkDoc.exists) throw Exception('Homework not found');

      final homeworkData = homeworkDoc.data()!;
      final dueDate = (homeworkData['dueDate'] as Timestamp).toDate();
      final isLate = DateTime.now().isAfter(dueDate);

      final submission = HomeworkSubmissionModel(
        submissionId: '', // Will be set by Firestore
        homeworkId: homeworkId,
        studentId: user.uid,
        studentName: studentData['name'] ?? '',
        submissionText: submissionText,
        attachmentUrls: attachmentUrls,
        status: isLate ? SubmissionStatus.late : SubmissionStatus.submitted,
        submittedAt: DateTime.now(),
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore.collection('homework_submissions').add(submission.toMap());
      
      // Update submission with ID
      await docRef.update({'submissionId': docRef.id});

      // Update homework submission count
      await _firestore.collection('homework').doc(homeworkId).update({
        'submittedCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit homework: $e');
    }
  }

  // Get student submissions for a homework
  Future<HomeworkSubmissionModel?> getStudentSubmission(String homeworkId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('homework_submissions')
          .where('homeworkId', isEqualTo: homeworkId)
          .where('studentId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return HomeworkSubmissionModel.fromDocument(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  // Get all submissions for a homework (Teacher)
  Stream<List<HomeworkSubmissionModel>> getHomeworkSubmissions(String homeworkId) {
    try {
      return _firestore
          .collection('homework_submissions')
          .where('homeworkId', isEqualTo: homeworkId)
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => HomeworkSubmissionModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Grade homework submission (Teacher)
  Future<void> gradeSubmission({
    required String submissionId,
    required int marksObtained,
    required int maxMarks,
    String? feedback,
  }) async {
    try {
      await _firestore.collection('homework_submissions').doc(submissionId).update({
        'marksObtained': marksObtained,
        'maxMarks': maxMarks,
        'feedback': feedback,
        'status': 'Graded', // This will be converted by the model's fromDocument
        'gradedBy': _auth.currentUser?.uid,
        'gradedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to grade submission: $e');
    }
  }

  // Delete homework (Teacher)
  Future<void> deleteHomework(String homeworkId) async {
    try {
      await _firestore.collection('homework').doc(homeworkId).delete();
    } catch (e) {
      throw Exception('Failed to delete homework: $e');
    }
  }
}
