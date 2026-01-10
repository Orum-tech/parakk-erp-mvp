import 'package:cloud_firestore/cloud_firestore.dart';

enum BehaviourType {
  positive,
  negative,
  neutral,
  appreciation,
}

class BehaviourLogModel {
  final String logId;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final BehaviourType behaviourType;
  final String remark;
  final String? teacherId;
  final String? teacherName;
  final String? subjectId;
  final String? subjectName;
  final DateTime date;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  BehaviourLogModel({
    required this.logId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.behaviourType,
    required this.remark,
    this.teacherId,
    this.teacherName,
    this.subjectId,
    this.subjectName,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });

  String get behaviourTypeString {
    switch (behaviourType) {
      case BehaviourType.positive:
        return 'Positive';
      case BehaviourType.negative:
        return 'Negative';
      case BehaviourType.neutral:
        return 'Neutral';
      case BehaviourType.appreciation:
        return 'Appreciation';
    }
  }

  factory BehaviourLogModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BehaviourLogModel(
      logId: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      behaviourType: _typeFromString(data['behaviourType'] ?? 'Neutral'),
      remark: data['remark'] ?? '',
      teacherId: data['teacherId'],
      teacherName: data['teacherName'],
      subjectId: data['subjectId'],
      subjectName: data['subjectName'],
      date: (data['date'] as Timestamp).toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static BehaviourType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'positive':
        return BehaviourType.positive;
      case 'negative':
        return BehaviourType.negative;
      case 'appreciation':
        return BehaviourType.appreciation;
      default:
        return BehaviourType.neutral;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'behaviourType': behaviourTypeString,
      'remark': remark,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  BehaviourLogModel copyWith({
    String? logId,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    BehaviourType? behaviourType,
    String? remark,
    String? teacherId,
    String? teacherName,
    String? subjectId,
    String? subjectName,
    DateTime? date,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return BehaviourLogModel(
      logId: logId ?? this.logId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      behaviourType: behaviourType ?? this.behaviourType,
      remark: remark ?? this.remark,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
