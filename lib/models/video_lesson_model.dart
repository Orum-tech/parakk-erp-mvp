import 'package:cloud_firestore/cloud_firestore.dart';

class VideoLessonModel {
  final String videoId;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String subject;
  final String? chapter;
  final String? topic;
  final String teacherId;
  final String teacherName;
  final List<String>? classIds; // Classes this video is available for
  final List<String>? targetAudience; // 'all' or specific classIds
  final int duration; // Duration in seconds
  final int views;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isActive;

  VideoLessonModel({
    required this.videoId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.subject,
    this.chapter,
    this.topic,
    required this.teacherId,
    required this.teacherName,
    this.classIds,
    this.targetAudience,
    required this.duration,
    this.views = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory VideoLessonModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoLessonModel(
      videoId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      subject: data['subject'] ?? '',
      chapter: data['chapter'],
      topic: data['topic'],
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      classIds: List<String>.from(data['classIds'] ?? []),
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
      duration: data['duration'] ?? 0,
      views: data['views'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classIds': classIds,
      'targetAudience': targetAudience,
      'duration': duration,
      'views': views,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'isActive': isActive,
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds}s';
  }
}
