import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teacher_model.dart';
import '../models/class_model.dart';

class ClassSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if teacher is class teacher
  Future<bool> isClassTeacher(String classId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) return false;

      final teacher = TeacherModel.fromDocument(teacherDoc);
      return teacher.classTeacherClassId == classId;
    } catch (e) {
      return false;
    }
  }

  // Get class data
  Future<ClassModel?> getClassData(String classId) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return null;
      return ClassModel.fromDocument(classDoc);
    } catch (e) {
      return null;
    }
  }

  // Get class settings
  Future<Map<String, dynamic>> getClassSettings(String classId) async {
    try {
      final settingsDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('settings')
          .doc('classSettings')
          .get();

      if (settingsDoc.exists) {
        return settingsDoc.data() ?? {};
      }

      // Return default settings
      return _getDefaultSettings();
    } catch (e) {
      return _getDefaultSettings();
    }
  }

  // Update class settings
  Future<void> updateClassSettings(String classId, Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify teacher is class teacher
      if (!await isClassTeacher(classId)) {
        throw Exception('Only class teacher can update class settings');
      }

      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('settings')
          .doc('classSettings')
          .set({
        ...settings,
        'updatedAt': Timestamp.now(),
        'updatedBy': user.uid,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update class settings: $e');
    }
  }

  // Update class basic info
  Future<void> updateClassInfo({
    required String classId,
    String? academicYear,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (!await isClassTeacher(classId)) {
        throw Exception('Only class teacher can update class info');
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (academicYear != null) {
        updateData['academicYear'] = academicYear;
      }

      if (description != null) {
        updateData['description'] = description;
      }

      await _firestore.collection('classes').doc(classId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update class info: $e');
    }
  }

  // Get default settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      // Attendance Settings
      'allowLateAttendance': true,
      'lateAttendanceCutoff': '09:00', // Time in HH:mm format
      'autoMarkAbsentAfter': '10:00',
      'requireReasonForAbsence': false,
      'allowParentMarkAttendance': false,

      // Homework Settings
      'autoLockHomework': false,
      'allowLateSubmission': true,
      'lateSubmissionPenalty': 0, // Percentage
      'maxLateSubmissionDays': 3,
      'requireAttachment': false,

      // Grading Settings
      'passingMarks': 33,
      'showRanksToStudents': true,
      'showGradesToStudents': true,
      'gradeScale': 'percentage', // percentage, letter, gpa
      'roundOffMarks': true,

      // Communication Settings
      'muteGroupChat': false,
      'allowStudentMessages': true,
      'allowParentMessages': true,
      'notifyOnHomework': true,
      'notifyOnTest': true,
      'notifyOnAttendance': false,

      // Privacy Settings
      'showClassRank': true,
      'showSubjectRank': false,
      'showAttendanceToParents': true,
      'showMarksToParents': true,

      // Academic Settings
      'workingDaysPerWeek': 5,
      'periodsPerDay': 8,
      'periodDuration': 40, // minutes
      'breakDuration': 15, // minutes
    };
  }

  // Get total students count
  Future<int> getTotalStudents(String classId) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('classId', isEqualTo: classId)
          .get();

      return studentsSnapshot.docs.length;
    } catch (e) {
      // Fallback to lowercase
      try {
        final studentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: classId)
            .get();
        return studentsSnapshot.docs.length;
      } catch (e2) {
        return 0;
      }
    }
  }

  // Get subjects for class
  Future<List<Map<String, dynamic>>> getClassSubjects(String classId) async {
    try {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) return [];

      final classData = classDoc.data()!;
      final subjectIds = List<String>.from(classData['subjectIds'] ?? []);

      if (subjectIds.isEmpty) return [];

      final subjects = <Map<String, dynamic>>[];
      for (var subjectId in subjectIds) {
        final subjectDoc = await _firestore.collection('subjects').doc(subjectId).get();
        if (subjectDoc.exists) {
          final subjectData = subjectDoc.data()!;
          subjects.add({
            'subjectId': subjectId,
            'subjectName': subjectData['subjectName'] ?? 'Unknown',
            'teacherName': subjectData['teacherName'],
          });
        }
      }

      return subjects;
    } catch (e) {
      return [];
    }
  }
}
