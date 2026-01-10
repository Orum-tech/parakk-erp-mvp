import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeTestModel {
  final String testId;
  final String title;
  final String? description;
  final String subjectId;
  final String subjectName;
  final String? topic;
  final int duration; // in minutes
  final int totalQuestions;
  final int? maxMarks;
  final List<String>? questionIds;
  final String? createdBy;
  final String? createdByName;
  final List<String>? classIds;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? attemptCount;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  PracticeTestModel({
    required this.testId,
    required this.title,
    this.description,
    required this.subjectId,
    required this.subjectName,
    this.topic,
    required this.duration,
    required this.totalQuestions,
    this.maxMarks,
    this.questionIds,
    this.createdBy,
    this.createdByName,
    this.classIds,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.attemptCount,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  factory PracticeTestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PracticeTestModel(
      testId: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      topic: data['topic'],
      duration: data['duration'] ?? 30,
      totalQuestions: data['totalQuestions'] ?? 0,
      maxMarks: data['maxMarks'],
      questionIds: List<String>.from(data['questionIds'] ?? []),
      createdBy: data['createdBy'],
      createdByName: data['createdByName'],
      classIds: List<String>.from(data['classIds'] ?? []),
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      attemptCount: data['attemptCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'topic': topic,
      'duration': duration,
      'totalQuestions': totalQuestions,
      'maxMarks': maxMarks,
      'questionIds': questionIds,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'classIds': classIds,
      'isActive': isActive,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'attemptCount': attemptCount ?? 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  PracticeTestModel copyWith({
    String? testId,
    String? title,
    String? description,
    String? subjectId,
    String? subjectName,
    String? topic,
    int? duration,
    int? totalQuestions,
    int? maxMarks,
    List<String>? questionIds,
    String? createdBy,
    String? createdByName,
    List<String>? classIds,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? attemptCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return PracticeTestModel(
      testId: testId ?? this.testId,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      topic: topic ?? this.topic,
      duration: duration ?? this.duration,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      maxMarks: maxMarks ?? this.maxMarks,
      questionIds: questionIds ?? this.questionIds,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      classIds: classIds ?? this.classIds,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
