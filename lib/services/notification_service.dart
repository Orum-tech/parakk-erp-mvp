import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification for a specific user
  Future<String> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? relatedId,
    String? relatedType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: '', // Will be set by Firestore
        title: title,
        body: body,
        type: type,
        priority: priority,
        userId: userId,
        relatedId: relatedId,
        relatedType: relatedType,
        data: data,
        isRead: false,
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Create notifications for multiple users
  Future<void> createNotificationsForUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? relatedId,
    String? relatedType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final notification = NotificationModel(
          notificationId: '', // Will be set by Firestore
          title: title,
          body: body,
          type: type,
          priority: priority,
          userId: userId,
          relatedId: relatedId,
          relatedType: relatedType,
          data: data,
          isRead: false,
          createdAt: Timestamp.now(),
        );

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create notifications: $e');
    }
  }

  // Get notifications for current user
  Stream<List<NotificationModel>> getUserNotifications() {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.value([]);

      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.value(0);

      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete read notifications: $e');
    }
  }

  // Create notification for homework assignment
  Future<void> notifyHomeworkAssigned({
    required List<String> studentIds,
    required String homeworkTitle,
    required String homeworkId,
    required DateTime dueDate,
  }) async {
    await createNotificationsForUsers(
      userIds: studentIds,
      title: 'New Homework Assigned',
      body: '$homeworkTitle is due on ${dueDate.toString().split(' ')[0]}',
      type: NotificationType.homework,
      priority: NotificationPriority.high,
      relatedId: homeworkId,
      relatedType: 'homework',
      data: {
        'dueDate': Timestamp.fromDate(dueDate).millisecondsSinceEpoch,
      },
    );
  }

  // Create notification for marks entry
  Future<void> notifyMarksEntered({
    required String studentId,
    required String examName,
    required String subjectName,
    required String examId,
  }) async {
    await createNotification(
      userId: studentId,
      title: 'Marks Updated',
      body: 'Your marks for $subjectName ($examName) have been updated',
      type: NotificationType.marks,
      priority: NotificationPriority.normal,
      relatedId: examId,
      relatedType: 'exam',
      data: {
        'examName': examName,
        'subjectName': subjectName,
      },
    );
  }

  // Create notification for test creation
  Future<void> notifyTestCreated({
    required List<String> studentIds,
    required String testTitle,
    required String testId,
    required DateTime startDate,
  }) async {
    await createNotificationsForUsers(
      userIds: studentIds,
      title: 'New Test Available',
      body: '$testTitle is now available',
      type: NotificationType.test,
      priority: NotificationPriority.high,
      relatedId: testId,
      relatedType: 'test',
      data: {
        'startDate': Timestamp.fromDate(startDate).millisecondsSinceEpoch,
      },
    );
  }

  // Create notification for leave request status
  Future<void> notifyLeaveRequestStatus({
    required String parentId,
    required String studentName,
    required String status,
    required String leaveRequestId,
  }) async {
    await createNotification(
      userId: parentId,
      title: 'Leave Request $status',
      body: 'Leave request for $studentName has been $status',
      type: NotificationType.leaveRequest,
      priority: status == 'Approved' ? NotificationPriority.normal : NotificationPriority.high,
      relatedId: leaveRequestId,
      relatedType: 'leaveRequest',
      data: {
        'status': status,
        'studentName': studentName,
      },
    );
  }

  // Create notification for attendance marked
  Future<void> notifyAttendanceMarked({
    required String parentId,
    required String studentName,
    required String status,
    required DateTime date,
  }) async {
    await createNotification(
      userId: parentId,
      title: 'Attendance Updated',
      body: '$studentName was marked as $status on ${date.toString().split(' ')[0]}',
      type: NotificationType.attendance,
      priority: status == 'Absent' ? NotificationPriority.high : NotificationPriority.normal,
      relatedType: 'attendance',
      data: {
        'status': status,
        'studentName': studentName,
        'date': Timestamp.fromDate(date).millisecondsSinceEpoch,
      },
    );
  }

  // Create notification for new message
  Future<void> notifyNewMessage({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await createNotification(
      userId: receiverId,
      title: 'New Message from $senderName',
      body: message,
      type: NotificationType.message,
      priority: NotificationPriority.normal,
      relatedId: chatId,
      relatedType: 'chat',
      data: {
        'senderName': senderName,
      },
    );
  }

  // Create notification for fee due
  Future<void> notifyFeeDue({
    required String parentId,
    required String studentName,
    required double amount,
    required DateTime dueDate,
  }) async {
    await createNotification(
      userId: parentId,
      title: 'Fee Payment Due',
      body: 'Fee payment of ₹${amount.toStringAsFixed(0)} for $studentName is due on ${dueDate.toString().split(' ')[0]}',
      type: NotificationType.fee,
      priority: NotificationPriority.high,
      relatedType: 'fee',
      data: {
        'amount': amount,
        'studentName': studentName,
        'dueDate': Timestamp.fromDate(dueDate).millisecondsSinceEpoch,
      },
    );
  }
}
