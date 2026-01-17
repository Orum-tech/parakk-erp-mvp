import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_lesson_model.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or update video lesson
  Future<String> createOrUpdateVideo({
    String? videoId,
    required String title,
    required String description,
    required String videoUrl,
    String? thumbnailUrl,
    required String subject,
    String? chapter,
    String? topic,
    required List<String>? targetAudience,
    required int duration,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacherData = teacherDoc.data()!;
      final teacherName = teacherData['name'] ?? 'Unknown Teacher';

      final videoData = {
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'subject': subject,
        'chapter': chapter,
        'topic': topic,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'targetAudience': targetAudience ?? ['all'],
        'duration': duration,
        'views': 0,
        'isActive': true,
        'createdAt': videoId == null ? Timestamp.now() : FieldValue.serverTimestamp(),
        'updatedAt': Timestamp.now(),
      };

      if (videoId == null) {
        final docRef = await _firestore.collection('video_lessons').add(videoData);
        return docRef.id;
      } else {
        await _firestore.collection('video_lessons').doc(videoId).update(videoData);
        return videoId;
      }
    } catch (e) {
      throw Exception('Failed to save video: $e');
    }
  }

  // Get all videos for a student (filtered by class)
  Stream<List<VideoLessonModel>> getStudentVideos(String? classId) {
    try {
      Query query = _firestore
          .collection('video_lessons')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => VideoLessonModel.fromDocument(doc))
            .where((video) {
              // Show if target audience includes 'all' or the specific class
              if (classId != null) {
                return video.targetAudience == null ||
                       video.targetAudience!.contains('all') ||
                       video.targetAudience!.contains(classId);
              }
              return video.targetAudience == null ||
                     video.targetAudience!.contains('all');
            })
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  // Get teacher's videos
  Stream<List<VideoLessonModel>> getTeacherVideos() {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('video_lessons')
          .where('teacherId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => VideoLessonModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch teacher videos: $e');
    }
  }

  // Increment view count
  Future<void> incrementViews(String videoId) async {
    try {
      await _firestore.collection('video_lessons').doc(videoId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Failed to increment views: $e');
    }
  }

  // Delete video
  Future<void> deleteVideo(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final videoDoc = await _firestore.collection('video_lessons').doc(videoId).get();
      if (videoDoc.exists) {
        final videoData = videoDoc.data()!;
        if (videoData['teacherId'] != user.uid) {
          throw Exception('Not authorized to delete this video');
        }
        await _firestore.collection('video_lessons').doc(videoId).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }
}
