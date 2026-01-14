import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/behaviour_log_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';

class BehaviourLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if teacher is class teacher for a class
  Future<bool> isClassTeacherForClass(String classId) async {
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

  // Get class teacher's class
  Future<String?> getClassTeacherClassId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) return null;

      final teacher = TeacherModel.fromDocument(teacherDoc);
      return teacher.classTeacherClassId;
    } catch (e) {
      return null;
    }
  }

  // Get all students in a class
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    try {
      QuerySnapshot studentsSnapshot;
      
      try {
        studentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'Student')
            .where('classId', isEqualTo: classId)
            .get();
      } catch (e) {
        try {
          studentsSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('classId', isEqualTo: classId)
              .get();
        } catch (e2) {
          // Fallback: fetch all students and filter in memory
          final allStudentsSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'Student')
              .get();
          
          final allStudents = allStudentsSnapshot.docs
              .map((doc) {
                try {
                  return StudentModel.fromDocument(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((student) => student != null && student.classId == classId)
              .cast<StudentModel>()
              .toList();
          
          // Sort by rollNumber
          allStudents.sort((a, b) {
            final rollA = a.rollNumber ?? '';
            final rollB = b.rollNumber ?? '';
            final numA = int.tryParse(rollA);
            final numB = int.tryParse(rollB);
            if (numA != null && numB != null) {
              return numA.compareTo(numB);
            }
            return rollA.compareTo(rollB);
          });
          
          return allStudents;
        }
      }
      
      final students = studentsSnapshot.docs
          .map((doc) {
            try {
              return StudentModel.fromDocument(doc);
            } catch (e) {
              return null;
            }
          })
          .where((student) => student != null)
          .cast<StudentModel>()
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
      print('Error getting students by class: $e');
      return [];
    }
  }

  // Get class name from classId
  Future<String> getClassName(String classId) async {
    try {
      // Parse className from classId (format: class_5_C)
      final parts = classId.replaceFirst('class_', '').split('_');
      if (parts.length == 2) {
        return 'Class ${parts[0]}-${parts[1]}';
      }
      return classId;
    } catch (e) {
      return classId;
    }
  }

  // Create a behavior log (Class Teacher only)
  Future<String> createBehaviourLog({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required BehaviourType behaviourType,
    required String remark,
    String? subjectId,
    String? subjectName,
    required DateTime date,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if teacher is class teacher for this class
      final isClassTeacher = await isClassTeacherForClass(classId);
      if (!isClassTeacher) {
        throw Exception('Only class teacher can create behavior logs for this class');
      }

      // Get teacher info
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) {
        throw Exception('Teacher not found');
      }
      final teacher = TeacherModel.fromDocument(teacherDoc);

      // Create behavior log document
      final logData = {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'className': className,
        'behaviourType': BehaviourLogModel(
          logId: '',
          studentId: studentId,
          studentName: studentName,
          classId: classId,
          className: className,
          behaviourType: behaviourType,
          remark: remark,
          date: date,
          createdAt: Timestamp.now(),
        ).behaviourTypeString,
        'remark': remark,
        'teacherId': user.uid,
        'teacherName': teacher.name,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.now(),
        'updatedAt': null,
      };

      final docRef = await _firestore.collection('behaviourLogs').add(logData);
      return docRef.id;
    } catch (e) {
      print('Error creating behaviour log: $e');
      rethrow;
    }
  }

  // Get behavior logs for a specific student
  Stream<List<BehaviourLogModel>> getStudentBehaviourLogs(String studentId) {
    return _firestore
        .collection('behaviourLogs')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BehaviourLogModel.fromDocument(doc))
          .toList();
    });
  }

  // Get behavior logs for a class (Class Teacher only)
  Stream<List<BehaviourLogModel>> getClassBehaviourLogs(String classId) {
    return _firestore
        .collection('behaviourLogs')
        .where('classId', isEqualTo: classId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BehaviourLogModel.fromDocument(doc))
          .toList();
    });
  }

  // Update a behavior log
  Future<void> updateBehaviourLog({
    required String logId,
    BehaviourType? behaviourType,
    String? remark,
    DateTime? date,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final logDoc = await _firestore.collection('behaviourLogs').doc(logId).get();
      if (!logDoc.exists) {
        throw Exception('Behaviour log not found');
      }

      final log = BehaviourLogModel.fromDocument(logDoc);
      
      // Check if teacher is class teacher for this class
      final isClassTeacher = await isClassTeacherForClass(log.classId);
      if (!isClassTeacher) {
        throw Exception('Only class teacher can update behavior logs for this class');
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (behaviourType != null) {
        updateData['behaviourType'] = BehaviourLogModel(
          logId: logId,
          studentId: log.studentId,
          studentName: log.studentName,
          classId: log.classId,
          className: log.className,
          behaviourType: behaviourType,
          remark: log.remark,
          date: log.date,
          createdAt: log.createdAt,
        ).behaviourTypeString;
      }

      if (remark != null) {
        updateData['remark'] = remark;
      }

      if (date != null) {
        updateData['date'] = Timestamp.fromDate(date);
      }

      await _firestore.collection('behaviourLogs').doc(logId).update(updateData);
    } catch (e) {
      print('Error updating behaviour log: $e');
      rethrow;
    }
  }

  // Delete a behavior log
  Future<void> deleteBehaviourLog(String logId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final logDoc = await _firestore.collection('behaviourLogs').doc(logId).get();
      if (!logDoc.exists) {
        throw Exception('Behaviour log not found');
      }

      final log = BehaviourLogModel.fromDocument(logDoc);
      
      // Check if teacher is class teacher for this class
      final isClassTeacher = await isClassTeacherForClass(log.classId);
      if (!isClassTeacher) {
        throw Exception('Only class teacher can delete behavior logs for this class');
      }

      await _firestore.collection('behaviourLogs').doc(logId).delete();
    } catch (e) {
      print('Error deleting behaviour log: $e');
      rethrow;
    }
  }
}
