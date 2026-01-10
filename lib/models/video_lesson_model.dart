import 'package:cloud_firestore/cloud_firestore.dart';

class VideoLessonModel {
  final String videoId;
  final String title;
  final String? description;
  final String subjectId;
  final String subjectName;
  final String? chapterName;
  final String? chapterNumber;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? duration; // in seconds
  final String? teacherId;
  final String? teacherName;
  final List<String>? classIds;
  final int? viewCount;
  final int? likeCount;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  VideoLessonModel({
    required this.videoId,
    required this.title,
    this.description,
    required this.subjectId,
    required this.subjectName,
    this.chapterName,
    this.chapterNumber,
    required this.videoUrl,
    this.thumbnailUrl,
    this.duration,
    this.teacherId,
    this.teacherName,
    this.classIds,
    this.viewCount,
    this.likeCount,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get formattedDuration {
    if (duration == null) return 'N/A';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes}m ${seconds}s';
  }

  factory VideoLessonModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoLessonModel(
      videoId: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      chapterName: data['chapterName'],
      chapterNumber: data['chapterNumber'],
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      duration: data['duration'],
      teacherId: data['teacherId'],
      teacherName: data['teacherName'],
      classIds: List<String>.from(data['classIds'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'chapterName': chapterName,
      'chapterNumber': chapterNumber,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classIds': classIds,
      'viewCount': viewCount ?? 0,
      'likeCount': likeCount ?? 0,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  VideoLessonModel copyWith({
    String? videoId,
    String? title,
    String? description,
    String? subjectId,
    String? subjectName,
    String? chapterName,
    String? chapterNumber,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    String? teacherId,
    String? teacherName,
    List<String>? classIds,
    int? viewCount,
    int? likeCount,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return VideoLessonModel(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterName: chapterName ?? this.chapterName,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      classIds: classIds ?? this.classIds,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
