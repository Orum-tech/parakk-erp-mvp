import 'package:cloud_firestore/cloud_firestore.dart';
import 'timetable_model.dart' show DayOfWeek;

class LessonPlanModel {
  final String planId;
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final String topic;
  final String? description;
  final DateTime plannedDate;
  final DayOfWeek? dayOfWeek;
  final int? periodNumber;
  final List<String>? objectives;
  final List<String>? activities;
  final String? homework;
  final bool isCompleted;
  final DateTime? completedDate;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  LessonPlanModel({
    required this.planId,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.topic,
    this.description,
    required this.plannedDate,
    this.dayOfWeek,
    this.periodNumber,
    this.objectives,
    this.activities,
    this.homework,
    this.isCompleted = false,
    this.completedDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory LessonPlanModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonPlanModel(
      planId: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      topic: data['topic'] ?? '',
      description: data['description'],
      plannedDate: (data['plannedDate'] as Timestamp).toDate(),
      dayOfWeek: data['dayOfWeek'] != null 
          ? _dayFromString(data['dayOfWeek'])
          : null,
      periodNumber: data['periodNumber'],
      objectives: List<String>.from(data['objectives'] ?? []),
      activities: List<String>.from(data['activities'] ?? []),
      homework: data['homework'],
      isCompleted: data['isCompleted'] ?? false,
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'topic': topic,
      'description': description,
      'plannedDate': Timestamp.fromDate(plannedDate),
      'dayOfWeek': dayOfWeek?.toString().split('.').last,
      'periodNumber': periodNumber,
      'objectives': objectives,
      'activities': activities,
      'homework': homework,
      'isCompleted': isCompleted,
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  LessonPlanModel copyWith({
    String? planId,
    String? subjectId,
    String? subjectName,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    String? topic,
    String? description,
    DateTime? plannedDate,
    DayOfWeek? dayOfWeek,
    int? periodNumber,
    List<String>? objectives,
    List<String>? activities,
    String? homework,
    bool? isCompleted,
    DateTime? completedDate,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return LessonPlanModel(
      planId: planId ?? this.planId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      plannedDate: plannedDate ?? this.plannedDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      periodNumber: periodNumber ?? this.periodNumber,
      objectives: objectives ?? this.objectives,
      activities: activities ?? this.activities,
      homework: homework ?? this.homework,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

  DayOfWeek _dayFromString(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
      case 'mon':
        return DayOfWeek.monday;
      case 'tuesday':
      case 'tue':
        return DayOfWeek.tuesday;
      case 'wednesday':
      case 'wed':
        return DayOfWeek.wednesday;
      case 'thursday':
      case 'thu':
        return DayOfWeek.thursday;
      case 'friday':
      case 'fri':
        return DayOfWeek.friday;
      case 'saturday':
      case 'sat':
        return DayOfWeek.saturday;
      case 'sunday':
      case 'sun':
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }
