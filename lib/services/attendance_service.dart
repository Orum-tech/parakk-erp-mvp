import 'package:flutter/foundation.dart';
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
        // use whereIn to handle both 'Student' and 'student' in a single query
        // This is much more efficient and avoids multiple round trips or complex error handling
        studentsSnapshot = await _firestore
            .collection('users')
            .where('role', whereIn: ['Student', 'student'])
            .where('classId', isEqualTo: classId)
            .get();
      } catch (e) {
        print('ERROR: Failed to fetch students for class $classId: $e');
        // RETHROW rather than hiding the error or fetching all users
        rethrow;
      }

      // Debug logging if no students found
      if (studentsSnapshot.docs.isEmpty) {
        print('DEBUG: getStudentsByClass - No students found for classId: $classId');
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
      // Get schoolId from first student (all students in same class should have same schoolId)
      final schoolId = students.isNotEmpty ? students.first.schoolId : '';

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
          schoolId: schoolId,
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
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      Query query = _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId);

      return query.snapshots().map((snapshot) {
        try {
          var attendanceList = snapshot.docs
              .map((doc) {
                try {
                  return AttendanceModel.fromDocument(doc);
                } catch (e) {
                  debugPrint('Error parsing attendance document ${doc.id}: $e');
                  return null;
                }
              })
              .where((attendance) => attendance != null)
              .cast<AttendanceModel>()
              .toList();

          // Filter by dates if provided
          if (startDate != null) {
            final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
            attendanceList = attendanceList.where((a) {
              final aDateOnly = DateTime(a.date.year, a.date.month, a.date.day);
              return aDateOnly.isAfter(startDateOnly.subtract(const Duration(days: 1)));
            }).toList();
          }
          if (endDate != null) {
            final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
            attendanceList = attendanceList.where((a) {
              final aDateOnly = DateTime(a.date.year, a.date.month, a.date.day);
              return aDateOnly.isBefore(endDateOnly.add(const Duration(days: 1)));
            }).toList();
          }

          // Sort by date descending
          attendanceList.sort((a, b) => b.date.compareTo(a.date));

          return attendanceList;
        } catch (e) {
          debugPrint('Error processing attendance snapshot: $e');
          return <AttendanceModel>[];
        }
      }).handleError((error) {
        debugPrint('Error in getStudentAttendance stream: $error');
        // Return empty list on error instead of throwing
        return <AttendanceModel>[];
      });
    } catch (e) {
      debugPrint('Error setting up getStudentAttendance query: $e');
      // Return empty stream on error
      return Stream.value(<AttendanceModel>[]);
    }
  }

  // Get attendance statistics for a student
  Future<Map<String, dynamic>> getStudentAttendanceStats(String studentId) async {
    try {
      // Query without date filter first to avoid composite index requirement
      // We'll filter in memory
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .get();

      debugPrint('getStudentAttendanceStats: Found ${attendanceSnapshot.docs.length} attendance records for studentId: $studentId');

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      int present = 0;
      int absent = 0;
      int late = 0;
      int excused = 0;

      for (var doc in attendanceSnapshot.docs) {
        try {
          final data = doc.data();
          final dateField = data['date'];
          
          // Check if date is within current month
          if (dateField != null) {
            DateTime attendanceDate;
            if (dateField is Timestamp) {
              attendanceDate = dateField.toDate();
            } else {
              continue; // Skip invalid date
            }
            
            // Filter by current month
            if (attendanceDate.year != now.year || attendanceDate.month != now.month) {
              continue;
            }
          } else {
            continue; // Skip records without date
          }

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
        } catch (e) {
          debugPrint('Error processing attendance document ${doc.id}: $e');
          continue;
        }
      }

      final total = present + absent + late + excused;
      final percentage = total > 0 ? (present / total * 100) : 0.0;

      debugPrint('getStudentAttendanceStats: present=$present, absent=$absent, late=$late, total=$total, percentage=$percentage');

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'excused': excused,
        'total': total,
        'percentage': percentage,
      };
    } catch (e) {
      debugPrint('Error in getStudentAttendanceStats: $e');
      // Return default stats instead of throwing
      return {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
        'total': 0,
        'percentage': 0.0,
      };
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
