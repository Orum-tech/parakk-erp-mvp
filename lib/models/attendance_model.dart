import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  holiday,
}

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String? subjectId;
  final String? subjectName;
  final DateTime date;
  final AttendanceStatus status;
  final String? remark;
  final String? markedBy;
  final String? markedByName;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    this.subjectId,
    this.subjectName,
    required this.date,
    required this.status,
    this.remark,
    this.markedBy,
    this.markedByName,
    required this.createdAt,
    this.updatedAt,
  });

  String get statusString {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }

  factory AttendanceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      attendanceId: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      subjectId: data['subjectId'],
      subjectName: data['subjectName'],
      date: (data['date'] as Timestamp).toDate(),
      status: _statusFromString(data['status'] ?? 'Present'),
      remark: data['remark'],
      markedBy: data['markedBy'],
      markedByName: data['markedByName'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static AttendanceStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.present;
    }
  }

  static String statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'status': statusString,
      'remark': remark,
      'markedBy': markedBy,
      'markedByName': markedByName,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  AttendanceModel copyWith({
    String? attendanceId,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    DateTime? date,
    AttendanceStatus? status,
    String? remark,
    String? markedBy,
    String? markedByName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
      status: status ?? this.status,
      remark: remark ?? this.remark,
      markedBy: markedBy ?? this.markedBy,
      markedByName: markedByName ?? this.markedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
