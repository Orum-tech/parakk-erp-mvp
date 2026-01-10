import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  final String? description;
  final String? teacherId;
  final String? teacherName;
  final List<String>? classIds;
  final int? totalPeriodsPerWeek;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  SubjectModel({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    this.description,
    this.teacherId,
    this.teacherName,
    this.classIds,
    this.totalPeriodsPerWeek,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectModel(
      subjectId: doc.id,
      subjectName: data['subjectName'] ?? '',
      subjectCode: data['subjectCode'],
      description: data['description'],
      teacherId: data['teacherId'],
      teacherName: data['teacherName'],
      classIds: List<String>.from(data['classIds'] ?? []),
      totalPeriodsPerWeek: data['totalPeriodsPerWeek'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classIds': classIds,
      'totalPeriodsPerWeek': totalPeriodsPerWeek,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  SubjectModel copyWith({
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? description,
    String? teacherId,
    String? teacherName,
    List<String>? classIds,
    int? totalPeriodsPerWeek,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SubjectModel(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      classIds: classIds ?? this.classIds,
      totalPeriodsPerWeek: totalPeriodsPerWeek ?? this.totalPeriodsPerWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
