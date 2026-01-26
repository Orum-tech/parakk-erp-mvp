import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String homeworkId;
  final String title;
  final String? description;
  final String schoolId; // REQUIRED - links homework to school
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final DateTime dueDate;
  final List<String>? attachmentUrls;
  final int? totalStudents;
  final int? submittedCount;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  HomeworkModel({
    required this.homeworkId,
    required this.title,
    required this.schoolId,
    this.description,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.dueDate,
    this.attachmentUrls,
    this.totalStudents,
    this.submittedCount,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  double get submissionPercentage => totalStudents != null && totalStudents! > 0
      ? (submittedCount ?? 0) / totalStudents! * 100
      : 0.0;

  factory HomeworkModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeworkModel(
      homeworkId: doc.id,
      title: data['title'] ?? '',
      schoolId: data['schoolId'] ?? '', // Will be required after migration
      description: data['description'],
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      totalStudents: data['totalStudents'],
      submittedCount: data['submittedCount'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeworkId': homeworkId,
      'title': title,
      'schoolId': schoolId,
      'description': description,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dueDate': Timestamp.fromDate(dueDate),
      'attachmentUrls': attachmentUrls,
      'totalStudents': totalStudents,
      'submittedCount': submittedCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  HomeworkModel copyWith({
    String? homeworkId,
    String? title,
    String? schoolId,
    String? description,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    DateTime? dueDate,
    List<String>? attachmentUrls,
    int? totalStudents,
    int? submittedCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return HomeworkModel(
      homeworkId: homeworkId ?? this.homeworkId,
      title: title ?? this.title,
      schoolId: schoolId ?? this.schoolId,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      dueDate: dueDate ?? this.dueDate,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      totalStudents: totalStudents ?? this.totalStudents,
      submittedCount: submittedCount ?? this.submittedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
