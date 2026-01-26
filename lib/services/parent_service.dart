import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/homework_model.dart';
import '../models/marks_model.dart';
import '../models/fee_model.dart';
import '../models/behaviour_log_model.dart';
import '../models/notice_model.dart';
import '../models/event_model.dart';
import 'attendance_service.dart';
import 'homework_service.dart';
import 'marks_service.dart';

class ParentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AttendanceService _attendanceService = AttendanceService();
  final HomeworkService _homeworkService = HomeworkService();
  final MarksService _marksService = MarksService();

  // Get all children (students) linked to this parent
  Future<List<StudentModel>> getChildren() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Query students where parentId matches current user's uid
      // Query students where parentId matches current user's uid
      // Use whereIn to handle role case sensitivity efficiently
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['Student', 'student'])
          .where('parentId', isEqualTo: user.uid)
          .get();

      final children = studentsSnapshot.docs
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

      return children;
    } catch (e) {
      throw Exception('Failed to fetch children: $e');
    }
  }

  // Get child's attendance history
  Stream<List<AttendanceModel>> getChildAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _attendanceService.getStudentAttendance(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get child's attendance statistics
  Future<Map<String, dynamic>> getChildAttendanceStats(String studentId) async {
    return await _attendanceService.getStudentAttendanceStats(studentId);
  }

  // Get child's homework
  Stream<List<HomeworkModel>> getChildHomework(String studentId) {
    try {
      // First get the student to find their classId
      return _firestore.collection('users').doc(studentId).snapshots().asyncExpand((studentDoc) {
        if (!studentDoc.exists) {
          return Stream<List<HomeworkModel>>.value([]);
        }

        try {
          final student = StudentModel.fromDocument(studentDoc);
          if (student.classId == null) {
            return Stream<List<HomeworkModel>>.value([]);
          }

          // Get homework for the student's class
          return _homeworkService.getStudentHomework(student.classId!);
        } catch (e) {
          return Stream<List<HomeworkModel>>.value([]);
        }
      });
    } catch (e) {
      return Stream<List<HomeworkModel>>.value([]);
    }
  }

  // Get child's marks/results
  Stream<List<MarksModel>> getChildMarks(String studentId) {
    return _marksService.getStudentMarks(studentId);
  }

  // Get child's fees
  Stream<List<FeeModel>> getChildFees(String studentId) {
    try {
      return _firestore
          .collection('fees')
          .where('studentId', isEqualTo: studentId)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => FeeModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch child fees: $e');
    }
  }

  // Get total fee amount due for a child
  Future<Map<String, dynamic>> getChildFeeSummary(String studentId) async {
    try {
      final feesSnapshot = await _firestore
          .collection('fees')
          .where('studentId', isEqualTo: studentId)
          .get();

      double totalAmount = 0.0;
      double totalPaid = 0.0;
      double totalDue = 0.0;
      int pendingCount = 0;
      int overdueCount = 0;

      for (var doc in feesSnapshot.docs) {
        final fee = FeeModel.fromDocument(doc);
        totalAmount += fee.amount;
        totalPaid += fee.paidAmount ?? 0.0;
        totalDue += fee.dueAmount ?? fee.amount;

        if (fee.status == PaymentStatus.pending) {
          pendingCount++;
        }
        if (fee.isOverdue) {
          overdueCount++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'totalPaid': totalPaid,
        'totalDue': totalDue,
        'pendingCount': pendingCount,
        'overdueCount': overdueCount,
      };
    } catch (e) {
      throw Exception('Failed to calculate fee summary: $e');
    }
  }

  // Get child's behaviour logs
  Stream<List<BehaviourLogModel>> getChildBehaviourLogs(String studentId) {
    try {
      return _firestore
          .collection('behaviour_logs')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => BehaviourLogModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch behaviour logs: $e');
    }
  }

  // Get notices for parents (targeted to 'parents' or 'all' or specific class)
  Stream<List<NoticeModel>> getNotices(String? classId) {
    try {
      Query query = _firestore
          .collection('notices')
          .where('isActive', isEqualTo: true);

      // If classId is provided, get notices for that class or all parents
      if (classId != null) {
        return query.snapshots().map((snapshot) {
          final notices = snapshot.docs
              .map((doc) => NoticeModel.fromDocument(doc))
              .where((notice) {
                // Show if target audience is 'all', 'parents', or matches the class
                final audience = notice.targetAudience?.toLowerCase() ?? '';
                return audience == 'all' || 
                       audience == 'parents' || 
                       notice.targetAudience == classId;
              })
              .toList();
          
          // Sort by createdAt descending
          notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notices;
        });
      } else {
        // Get all parent notices
        return query.snapshots().map((snapshot) {
          final notices = snapshot.docs
              .map((doc) => NoticeModel.fromDocument(doc))
              .where((notice) {
                final audience = notice.targetAudience?.toLowerCase() ?? '';
                return audience == 'all' || audience == 'parents';
              })
              .toList();
          
          notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notices;
        });
      }
    } catch (e) {
      throw Exception('Failed to fetch notices: $e');
    }
  }

  // Get events for parents
  Stream<List<EventModel>> getEvents(String? classId) {
    try {
      Query query = _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .orderBy('eventDate', descending: false);

      return query.snapshots().map((snapshot) {
        final events = snapshot.docs
            .map((doc) => EventModel.fromDocument(doc))
            .where((event) {
              // Show if target audience includes 'all' or the specific class
              if (classId != null) {
                return event.targetAudience == null || 
                       event.targetAudience!.contains('all') ||
                       event.targetAudience!.contains(classId);
              }
              return event.targetAudience == null || 
                     event.targetAudience!.contains('all');
            })
            .toList();
        
        return events;
      });
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Get child's class teacher info
  Future<Map<String, String>?> getClassTeacherInfo(String classId) async {
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
        'teacherName': teacherData['name'] ?? 'Unknown',
        'email': teacherData['email'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  // Link a child (student) to parent by email
  Future<void> linkChildByEmail(String childEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Find student with matching email
      // Use whereIn for role to handle both cases in one query
      final studentQuery = await _firestore
          .collection('users')
          .where('role', whereIn: ['Student', 'student'])
          .where('email', isEqualTo: childEmail.toLowerCase())
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        throw Exception('No student found with this email. Please make sure your child has signed up with this email address.');
      }

      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();
      
      // Check if student already has a parent linked
      final existingParentId = studentData['parentId'] as String?;
      if (existingParentId != null && existingParentId.isNotEmpty) {
        if (existingParentId == user.uid) {
          throw Exception('This child is already linked to your account.');
        } else {
          throw Exception('This child is already linked to another parent account.');
        }
      }

      // Get parent data
      final parentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!parentDoc.exists) throw Exception('Parent account not found');
      
      final parentData = parentDoc.data()!;
      final parentName = parentData['name'] ?? '';

      // Link student to parent
      await _firestore.collection('users').doc(studentDoc.id).update({
        'parentId': user.uid,
        'parentName': parentName,
        'parentEmail': user.email,
      });
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to link child: $e');
    }
  }
}
