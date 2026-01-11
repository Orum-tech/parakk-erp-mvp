import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';

class AttendanceService {
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
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      QuerySnapshot studentsSnapshot;
      
      try {
        // Try with 'Student' first (capitalized, as stored in Firestore)
        studentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'Student')
            .where('classId', isEqualTo: classId)
            .get();
      } catch (e) {
        // If query fails (e.g., missing index), try with lowercase 'student'
        try {
          studentsSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('classId', isEqualTo: classId)
              .get();
        } catch (e2) {
          // Last resort: fetch all students and filter in memory
          print('WARNING: Composite query failed, fetching all students and filtering in memory');
          print('Error 1: $e');
          print('Error 2: $e2');
          
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

      // Debug logging if no students found
      if (studentsSnapshot.docs.isEmpty) {
        print('DEBUG: getStudentsByClass - No students found for classId: $classId');
        print('DEBUG: Checking if class exists and has students...');
        
        // Check if class exists
        final classDoc = await _firestore.collection('classes').doc(classId).get();
        print('DEBUG: Class document exists: ${classDoc.exists}');
        
        // Check if there are any students at all
        final allStudentsCheck = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'Student')
            .limit(5)
            .get();
        print('DEBUG: Total students in system: ${allStudentsCheck.docs.length}');
        
        if (allStudentsCheck.docs.isNotEmpty) {
          for (var doc in allStudentsCheck.docs) {
            try {
              final student = StudentModel.fromDocument(doc);
              print('DEBUG: Sample student - name: ${student.name}, classId: ${student.classId}');
            } catch (e) {
              print('DEBUG: Could not parse sample student: $e');
            }
          }
        }
      }

      final students = studentsSnapshot.docs
          .map((doc) {
            try {
              return StudentModel.fromDocument(doc);
            } catch (e) {
              print('ERROR: Failed to parse student document ${doc.id}: $e');
              return null;
            }
          })
          .where((student) => student != null)
          .cast<StudentModel>()
          .toList();

      // Sort by rollNumber in memory (handle null values)
      students.sort((a, b) {
        final rollA = a.rollNumber ?? '';
        final rollB = b.rollNumber ?? '';
        
        // Try to parse as numbers for proper numeric sorting
        final numA = int.tryParse(rollA);
        final numB = int.tryParse(rollB);
        
        if (numA != null && numB != null) {
          return numA.compareTo(numB);
        }
        // If not numbers, sort alphabetically
        return rollA.compareTo(rollB);
      });

      return students;
    } catch (e) {
      print('ERROR: getStudentsByClass failed for classId: $classId, error: $e');
      rethrow;
    }
  }

  // Mark attendance for multiple students (Class Teacher only)
  Future<void> markAttendance({
    required String classId,
    required String className,
    required DateTime date,
    required Map<String, AttendanceStatus> studentAttendance, // studentId -> status
    String? subjectId,
    String? subjectName,
    Map<String, String>? remarks, // studentId -> remark
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify teacher is class teacher for this class
      if (!await isClassTeacherForClass(classId)) {
        throw Exception('Only class teacher can mark attendance for this class');
      }

      // Get teacher info
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacherName = teacherDoc.data()!['name'] ?? '';

      // Get student info for names
      final students = await getStudentsByClass(classId);
      final studentMap = {for (var s in students) s.uid: s};

      final batch = _firestore.batch();
      final dateOnly = DateTime(date.year, date.month, date.day);

      for (var entry in studentAttendance.entries) {
        final studentId = entry.key;
        final status = entry.value;
        final student = studentMap[studentId];

        if (student == null) continue;

        // Create attendance document ID based on student, class, date
        final attendanceId = '${studentId}_${classId}_${dateOnly.millisecondsSinceEpoch}';
        final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

        final attendance = AttendanceModel(
          attendanceId: attendanceId,
          studentId: studentId,
          studentName: student.name,
          classId: classId,
          className: className,
          subjectId: subjectId,
          subjectName: subjectName,
          date: dateOnly,
          status: status,
          remark: remarks?[studentId],
          markedBy: user.uid,
          markedByName: teacherName,
          createdAt: Timestamp.now(),
        );

        batch.set(attendanceRef, attendance.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // Get attendance for a specific date and class
  Stream<List<AttendanceModel>> getAttendanceByDateAndClass({
    required String classId,
    required DateTime date,
    String? subjectId,
  }) {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOfDay = Timestamp.fromDate(dateOnly);
      final endOfDay = Timestamp.fromDate(
        dateOnly.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
      );

      Query query = _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay);

      if (subjectId != null) {
        query = query.where('subjectId', isEqualTo: subjectId);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => AttendanceModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  // Get student's attendance history
  Stream<List<AttendanceModel>> getStudentAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query query = _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId);

      // Note: Firestore requires composite index if using multiple where clauses with orderBy
      // For now, we'll fetch all and filter in memory if dates are provided
      return query.snapshots().map((snapshot) {
        var attendanceList = snapshot.docs
            .map((doc) => AttendanceModel.fromDocument(doc))
            .toList();

        // Filter by dates if provided
        if (startDate != null) {
          attendanceList = attendanceList.where((a) => a.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
        }
        if (endDate != null) {
          attendanceList = attendanceList.where((a) => a.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
        }

        // Sort by date descending
        attendanceList.sort((a, b) => b.date.compareTo(a.date));

        return attendanceList;
      });
    } catch (e) {
      throw Exception('Failed to fetch student attendance: $e');
    }
  }

  // Get attendance statistics for a student
  Future<Map<String, dynamic>> getStudentAttendanceStats(String studentId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      int present = 0;
      int absent = 0;
      int late = 0;
      int excused = 0;

      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'Present';
        switch (status.toLowerCase()) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
          case 'excused':
            excused++;
            break;
        }
      }

      final total = present + absent + late + excused;
      final percentage = total > 0 ? (present / total * 100) : 0.0;

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'excused': excused,
        'total': total,
        'percentage': percentage,
      };
    } catch (e) {
      throw Exception('Failed to get attendance stats: $e');
    }
  }

  // Update attendance for a single student
  Future<void> updateAttendance({
    required String attendanceId,
    required AttendanceStatus status,
    String? remark,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final attendanceDoc = await _firestore.collection('attendance').doc(attendanceId).get();
      if (!attendanceDoc.exists) throw Exception('Attendance record not found');

      final attendance = AttendanceModel.fromDocument(attendanceDoc);

      // Verify teacher is class teacher for this class
      if (!await isClassTeacherForClass(attendance.classId)) {
        throw Exception('Only class teacher can update attendance for this class');
      }

      await _firestore.collection('attendance').doc(attendanceId).update({
        'status': AttendanceModel.statusToString(status),
        'remark': remark,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }
}
