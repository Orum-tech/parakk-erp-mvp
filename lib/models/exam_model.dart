import 'package:cloud_firestore/cloud_firestore.dart';

enum ExamType {
  unitTest,
  midTerm,
  finalExam,
  quiz,
  assignment,
  project,
}

class ExamModel {
  final String examId;
  final String examName;
  final ExamType examType;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final DateTime examDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final int maxMarks;
  final int? passingMarks;
  final String? instructions;
  final String? syllabus;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ExamModel({
    required this.examId,
    required this.examName,
    required this.examType,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.examDate,
    this.startTime,
    this.endTime,
    required this.maxMarks,
    this.passingMarks,
    this.instructions,
    this.syllabus,
    required this.createdAt,
    this.updatedAt,
  });

  String get examTypeString {
    switch (examType) {
      case ExamType.unitTest:
        return 'Unit Test';
      case ExamType.midTerm:
        return 'Mid-Term';
      case ExamType.finalExam:
        return 'Final Exam';
      case ExamType.quiz:
        return 'Quiz';
      case ExamType.assignment:
        return 'Assignment';
      case ExamType.project:
        return 'Project';
    }
  }

  factory ExamModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamModel(
      examId: doc.id,
      examName: data['examName'] ?? '',
      examType: _typeFromString(data['examType'] ?? 'Quiz'),
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      examDate: (data['examDate'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      maxMarks: data['maxMarks'] ?? 100,
      passingMarks: data['passingMarks'],
      instructions: data['instructions'],
      syllabus: data['syllabus'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static ExamType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'unittest':
      case 'unit test':
        return ExamType.unitTest;
      case 'midterm':
      case 'mid-term':
        return ExamType.midTerm;
      case 'finalexam':
      case 'final exam':
        return ExamType.finalExam;
      case 'quiz':
        return ExamType.quiz;
      case 'assignment':
        return ExamType.assignment;
      case 'project':
        return ExamType.project;
      default:
        return ExamType.quiz;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'examName': examName,
      'examType': examTypeString,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'examDate': Timestamp.fromDate(examDate),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'maxMarks': maxMarks,
      'passingMarks': passingMarks,
      'instructions': instructions,
      'syllabus': syllabus,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  ExamModel copyWith({
    String? examId,
    String? examName,
    ExamType? examType,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    DateTime? examDate,
    DateTime? startTime,
    DateTime? endTime,
    int? maxMarks,
    int? passingMarks,
    String? instructions,
    String? syllabus,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ExamModel(
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      examType: examType ?? this.examType,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxMarks: maxMarks ?? this.maxMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      instructions: instructions ?? this.instructions,
      syllabus: syllabus ?? this.syllabus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
