import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice_model.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create notice (Teacher/Admin)
  Future<String> createNotice({
    required String title,
    required String description,
    required NoticeType noticeType,
    String? targetAudience, // 'all', 'students', 'teachers', 'parents', or classId
    List<String>? attachmentUrls,
    DateTime? expiryDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get creator info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');
      final userData = userDoc.data()!;
      final creatorName = userData['name'] ?? 'Unknown';

      final notice = NoticeModel(
        noticeId: '', // Will be set by Firestore
        title: title,
        description: description,
        noticeType: noticeType,
        targetAudience: targetAudience ?? 'all',
        createdBy: user.uid,
        createdByName: creatorName,
        attachmentUrls: attachmentUrls,
        expiryDate: expiryDate,
        isActive: true,
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore.collection('notices').add(notice.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notice: $e');
    }
  }

  // Get notices for teachers (all notices they created or all notices)
  Stream<List<NoticeModel>> getTeacherNotices({String? classId}) {
    try {
      Query query = _firestore
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        final notices = snapshot.docs
            .map((doc) => NoticeModel.fromDocument(doc))
            .where((notice) {
              // If classId provided, show notices for that class or all
              if (classId != null) {
                return notice.targetAudience == null ||
                       notice.targetAudience == 'all' ||
                       notice.targetAudience == classId;
              }
              return true; // Show all notices
            })
            .toList();
        
        return notices;
      });
    } catch (e) {
      throw Exception('Failed to fetch notices: $e');
    }
  }

  // Get notices for students
  Stream<List<NoticeModel>> getStudentNotices(String? classId) {
    try {
      Query query = _firestore
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        final notices = snapshot.docs
            .map((doc) => NoticeModel.fromDocument(doc))
            .where((notice) {
              final audience = notice.targetAudience?.toLowerCase() ?? '';
              // Show if target audience is 'all', 'students', or matches the class
              if (classId != null) {
                return audience == 'all' || 
                       audience == 'students' || 
                       notice.targetAudience == classId;
              }
              return audience == 'all' || audience == 'students';
            })
            .toList();
        
        return notices;
      });
    } catch (e) {
      throw Exception('Failed to fetch notices: $e');
    }
  }

  // Delete notice
  Future<void> deleteNotice(String noticeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noticeDoc = await _firestore.collection('notices').doc(noticeId).get();
      if (!noticeDoc.exists) throw Exception('Notice not found');

      final noticeData = noticeDoc.data()!;
      if (noticeData['createdBy'] != user.uid) {
        throw Exception('Not authorized to delete this notice');
      }

      await _firestore.collection('notices').doc(noticeId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete notice: $e');
    }
  }
}
