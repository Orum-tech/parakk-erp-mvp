import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_request_model.dart';
import 'notification_service.dart';

class LeaveRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create leave request (for parents)
  Future<String> createLeaveRequest({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required LeaveType leaveType,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final numberOfDays = endDate.difference(startDate).inDays + 1;

      String leaveTypeString;
      switch (leaveType) {
        case LeaveType.medical:
          leaveTypeString = 'medical';
          break;
        case LeaveType.personal:
          leaveTypeString = 'personal';
          break;
        case LeaveType.familyFunction:
          leaveTypeString = 'familyFunction';
          break;
        case LeaveType.emergency:
          leaveTypeString = 'emergency';
          break;
        case LeaveType.other:
          leaveTypeString = 'other';
          break;
      }

      final leaveData = {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'className': className,
        'leaveType': leaveTypeString,
        'reason': reason,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'numberOfDays': numberOfDays,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      final docRef = await _firestore.collection('leave_requests').add(leaveData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create leave request: $e');
    }
  }

  // Get leave requests for a teacher's class
  Stream<List<LeaveRequestModel>> getClassLeaveRequests(String? classId) {
    try {
      if (classId == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('leave_requests')
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => LeaveRequestModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch leave requests: $e');
    }
  }

  // Get leave requests for a student (for parents)
  Stream<List<LeaveRequestModel>> getStudentLeaveRequests(String studentId) {
    try {
      return _firestore
          .collection('leave_requests')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => LeaveRequestModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch student leave requests: $e');
    }
  }

  // Approve leave request
  Future<void> approveLeaveRequest(String leaveId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacherData = teacherDoc.data()!;
      final teacherName = teacherData['name'] ?? 'Unknown Teacher';

      // Get leave request to find parent ID
      final leaveDoc = await _firestore.collection('leave_requests').doc(leaveId).get();
      if (leaveDoc.exists) {
        final leaveData = leaveDoc.data()!;
        final studentId = leaveData['studentId'] as String?;
        final studentName = leaveData['studentName'] as String? ?? 'Student';

        await _firestore.collection('leave_requests').doc(leaveId).update({
          'status': 'approved',
          'approvedBy': user.uid,
          'approvedByName': teacherName,
          'approvedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Create notification for parent
        if (studentId != null) {
          try {
            final studentDoc = await _firestore.collection('users').doc(studentId).get();
            if (studentDoc.exists) {
              final parentId = studentDoc.data()?['parentId'] as String?;
              if (parentId != null) {
                final notificationService = NotificationService();
                await notificationService.notifyLeaveRequestStatus(
                  parentId: parentId,
                  studentName: studentName,
                  status: 'Approved',
                  leaveRequestId: leaveId,
                );
              }
            }
          } catch (e) {
            // Don't fail leave approval if notification fails
            debugPrint('Error creating notification: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to approve leave request: $e');
    }
  }

  // Reject leave request
  Future<void> rejectLeaveRequest(String leaveId, String? rejectionReason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacherData = teacherDoc.data()!;
      final teacherName = teacherData['name'] ?? 'Unknown Teacher';

      // Get leave request to find parent ID
      final leaveDoc = await _firestore.collection('leave_requests').doc(leaveId).get();
      if (leaveDoc.exists) {
        final leaveData = leaveDoc.data()!;
        final studentId = leaveData['studentId'] as String?;
        final studentName = leaveData['studentName'] as String? ?? 'Student';

        await _firestore.collection('leave_requests').doc(leaveId).update({
          'status': 'rejected',
          'approvedBy': user.uid,
          'approvedByName': teacherName,
          'approvedAt': Timestamp.now(),
          'rejectionReason': rejectionReason,
          'updatedAt': Timestamp.now(),
        });

        // Create notification for parent
        if (studentId != null) {
          try {
            final studentDoc = await _firestore.collection('users').doc(studentId).get();
            if (studentDoc.exists) {
              final parentId = studentDoc.data()?['parentId'] as String?;
              if (parentId != null) {
                final notificationService = NotificationService();
                await notificationService.notifyLeaveRequestStatus(
                  parentId: parentId,
                  studentName: studentName,
                  status: 'Rejected',
                  leaveRequestId: leaveId,
                );
              }
            }
          } catch (e) {
            // Don't fail leave rejection if notification fails
            debugPrint('Error creating notification: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to reject leave request: $e');
    }
  }

  // Delete leave request (for parents, if pending)
  Future<void> deleteLeaveRequest(String leaveId) async {
    try {
      final leaveDoc = await _firestore.collection('leave_requests').doc(leaveId).get();
      if (!leaveDoc.exists) throw Exception('Leave request not found');

      final leaveData = leaveDoc.data()!;
      final status = leaveData['status'] as String?;

      if (status != 'pending') {
        throw Exception('Only pending leave requests can be deleted');
      }

      await _firestore.collection('leave_requests').doc(leaveId).delete();
    } catch (e) {
      throw Exception('Failed to delete leave request: $e');
    }
  }
}
