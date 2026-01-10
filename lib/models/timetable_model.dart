import 'package:cloud_firestore/cloud_firestore.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class TimetableModel {
  final String timetableId;
  final String classId;
  final String className;
  final DayOfWeek day;
  final int periodNumber;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final String? room;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBreak;
  final String? breakType; // 'lunch', 'short break', etc.
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  TimetableModel({
    required this.timetableId,
    required this.classId,
    required this.className,
    required this.day,
    required this.periodNumber,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    this.room,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
    this.breakType,
    required this.createdAt,
    this.updatedAt,
  });

  String get dayString {
    switch (day) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  factory TimetableModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimetableModel(
      timetableId: doc.id,
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      day: _dayFromString(data['day'] ?? 'Monday'),
      periodNumber: data['periodNumber'] ?? 1,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      room: data['room'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      isBreak: data['isBreak'] ?? false,
      breakType: data['breakType'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static DayOfWeek _dayFromString(String day) {
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

  Map<String, dynamic> toMap() {
    return {
      'timetableId': timetableId,
      'classId': classId,
      'className': className,
      'day': dayString,
      'periodNumber': periodNumber,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'room': room,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isBreak': isBreak,
      'breakType': breakType,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  TimetableModel copyWith({
    String? timetableId,
    String? classId,
    String? className,
    DayOfWeek? day,
    int? periodNumber,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    String? room,
    DateTime? startTime,
    DateTime? endTime,
    bool? isBreak,
    String? breakType,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return TimetableModel(
      timetableId: timetableId ?? this.timetableId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      day: day ?? this.day,
      periodNumber: periodNumber ?? this.periodNumber,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      room: room ?? this.room,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBreak: isBreak ?? this.isBreak,
      breakType: breakType ?? this.breakType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
