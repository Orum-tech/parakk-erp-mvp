import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String classId;
  final String className;
  final String section;
  final String? classTeacherId;
  final String? classTeacherName;
  final int? totalStudents;
  final String? academicYear;
  final List<String>? subjectIds;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ClassModel({
    required this.classId,
    required this.className,
    required this.section,
    this.classTeacherId,
    this.classTeacherName,
    this.totalStudents,
    this.academicYear,
    this.subjectIds,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullClassName => '$className-$section';

  factory ClassModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      classId: doc.id,
      className: data['className'] ?? '',
      section: data['section'] ?? '',
      classTeacherId: data['classTeacherId'],
      classTeacherName: data['classTeacherName'],
      totalStudents: data['totalStudents'],
      academicYear: data['academicYear'],
      subjectIds: List<String>.from(data['subjectIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'section': section,
      'classTeacherId': classTeacherId,
      'classTeacherName': classTeacherName,
      'totalStudents': totalStudents,
      'academicYear': academicYear,
      'subjectIds': subjectIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  ClassModel copyWith({
    String? classId,
    String? className,
    String? section,
    String? classTeacherId,
    String? classTeacherName,
    int? totalStudents,
    String? academicYear,
    List<String>? subjectIds,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ClassModel(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      classTeacherName: classTeacherName ?? this.classTeacherName,
      totalStudents: totalStudents ?? this.totalStudents,
      academicYear: academicYear ?? this.academicYear,
      subjectIds: subjectIds ?? this.subjectIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
