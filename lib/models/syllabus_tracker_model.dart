import 'package:cloud_firestore/cloud_firestore.dart';

class SyllabusTrackerModel {
  final String trackerId;
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final String chapterName;
  final int? chapterNumber;
  final String? description;
  final bool isCompleted;
  final DateTime? completedDate;
  final DateTime? plannedDate;
  final int? estimatedDays;
  final String? notes;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  SyllabusTrackerModel({
    required this.trackerId,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.chapterName,
    this.chapterNumber,
    this.description,
    this.isCompleted = false,
    this.completedDate,
    this.plannedDate,
    this.estimatedDays,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory SyllabusTrackerModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SyllabusTrackerModel(
      trackerId: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      chapterName: data['chapterName'] ?? '',
      chapterNumber: data['chapterNumber'],
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      plannedDate: (data['plannedDate'] as Timestamp?)?.toDate(),
      estimatedDays: data['estimatedDays'],
      notes: data['notes'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackerId': trackerId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'chapterName': chapterName,
      'chapterNumber': chapterNumber,
      'description': description,
      'isCompleted': isCompleted,
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'plannedDate': plannedDate != null ? Timestamp.fromDate(plannedDate!) : null,
      'estimatedDays': estimatedDays,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  SyllabusTrackerModel copyWith({
    String? trackerId,
    String? subjectId,
    String? subjectName,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    String? chapterName,
    int? chapterNumber,
    String? description,
    bool? isCompleted,
    DateTime? completedDate,
    DateTime? plannedDate,
    int? estimatedDays,
    String? notes,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SyllabusTrackerModel(
      trackerId: trackerId ?? this.trackerId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      chapterName: chapterName ?? this.chapterName,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      plannedDate: plannedDate ?? this.plannedDate,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
