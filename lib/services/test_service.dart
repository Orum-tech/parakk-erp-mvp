import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/test_model.dart';
import 'notification_service.dart';
import 'attendance_service.dart';

class TestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or update test
  Future<String> createOrUpdateTest({
    String? testId,
    required String title,
    required String description,
    required String subject,
    String? chapter,
    String? topic,
    required TestType testType,
    required List<TestQuestion> questions,
    required int duration,
    required DateTime startDate,
    DateTime? endDate,
    required List<String>? targetAudience,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacherData = teacherDoc.data()!;
      final teacherName = teacherData['name'] ?? 'Unknown Teacher';

      final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);

      final testData = {
        'title': title,
        'description': description,
        'subject': subject,
        'chapter': chapter,
        'topic': topic,
        'testType': testType.toString().split('.').last,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'questions': questions.map((q) => q.toMap()).toList(),
        'totalMarks': totalMarks,
        'duration': duration,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'targetAudience': targetAudience ?? ['all'],
        'isActive': true,
        'createdAt': testId == null ? Timestamp.now() : FieldValue.serverTimestamp(),
        'updatedAt': Timestamp.now(),
      };

      String finalTestId;
      if (testId == null) {
        final docRef = await _firestore.collection('tests').add(testData);
        finalTestId = docRef.id;
      } else {
        await _firestore.collection('tests').doc(testId).update(testData);
        finalTestId = testId;
      }

      // Create notifications for students if test is for specific classes
      if (targetAudience != null && targetAudience.isNotEmpty && !targetAudience.contains('all')) {
        try {
          final attendanceService = AttendanceService();
          final notificationService = NotificationService();
          final allStudentIds = <String>[];

          for (final classId in targetAudience) {
            final students = await attendanceService.getStudentsByClass(classId);
            allStudentIds.addAll(students.map((s) => s.uid));
          }

          if (allStudentIds.isNotEmpty) {
            await notificationService.notifyTestCreated(
              studentIds: allStudentIds,
              testTitle: title,
              testId: finalTestId,
              startDate: startDate,
            );
          }
        } catch (e) {
          // Don't fail test creation if notification fails
          debugPrint('Error creating notifications: $e');
        }
      }

      return finalTestId;
    } catch (e) {
      throw Exception('Failed to save test: $e');
    }
  }

  // Get all tests for a student (filtered by class)
  Stream<List<TestModel>> getStudentTests(String? classId) {
    try {
      Query query = _firestore
          .collection('tests')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => TestModel.fromDocument(doc))
            .where((test) {
              // Show if target audience includes 'all' or the specific class
              if (classId != null) {
                return test.targetAudience == null ||
                       test.targetAudience!.contains('all') ||
                       test.targetAudience!.contains(classId);
              }
              return test.targetAudience == null ||
                     test.targetAudience!.contains('all');
            })
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch tests: $e');
    }
  }

  // Get teacher's tests
  Stream<List<TestModel>> getTeacherTests() {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('tests')
          .where('teacherId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TestModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch teacher tests: $e');
    }
  }

  // Delete test
  Future<void> deleteTest(String testId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final testDoc = await _firestore.collection('tests').doc(testId).get();
      if (testDoc.exists) {
        final testData = testDoc.data()!;
        if (testData['teacherId'] != user.uid) {
          throw Exception('Not authorized to delete this test');
        }
        await _firestore.collection('tests').doc(testId).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete test: $e');
    }
  }

  // Submit test result
  Future<void> submitTestResult({
    required String testId,
    required String studentId,
    required Map<int, int?> answers,
    required int score,
    required int percentage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Convert answers map to list format for Firestore
      final answersList = answers.entries.map((e) => {
        'questionIndex': e.key,
        'selectedAnswer': e.value,
      }).toList();

      await _firestore.collection('test_results').add({
        'testId': testId,
        'studentId': studentId,
        'answers': answersList,
        'score': score,
        'percentage': percentage,
        'submittedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to submit test result: $e');
    }
  }
}
