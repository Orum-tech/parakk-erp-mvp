import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected,
}

enum LeaveType {
  medical,
  personal,
  familyFunction,
  emergency,
  other,
}

class LeaveRequestModel {
  final String leaveId;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final LeaveType leaveType;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final LeaveStatus status;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  LeaveRequestModel({
    required this.leaveId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.leaveType,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  String get leaveTypeString {
    switch (leaveType) {
      case LeaveType.medical:
        return 'Medical Leave';
      case LeaveType.personal:
        return 'Personal Leave';
      case LeaveType.familyFunction:
        return 'Family Function';
      case LeaveType.emergency:
        return 'Emergency';
      case LeaveType.other:
        return 'Other';
    }
  }

  String get statusString {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  factory LeaveRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    return LeaveRequestModel(
      leaveId: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      leaveType: _typeFromString(data['leaveType'] ?? 'Other'),
      reason: data['reason'] ?? '',
      startDate: startDate,
      endDate: endDate,
      numberOfDays: data['numberOfDays'] ?? endDate.difference(startDate).inDays + 1,
      status: _statusFromString(data['status'] ?? 'Pending'),
      approvedBy: data['approvedBy'],
      approvedByName: data['approvedByName'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static LeaveType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return LeaveType.medical;
      case 'personal':
        return LeaveType.personal;
      case 'familyfunction':
      case 'family function':
        return LeaveType.familyFunction;
      case 'emergency':
        return LeaveType.emergency;
      default:
        return LeaveType.other;
    }
  }

  static LeaveStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'leaveId': leaveId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'leaveType': leaveTypeString,
      'reason': reason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'numberOfDays': numberOfDays,
      'status': statusString,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  LeaveRequestModel copyWith({
    String? leaveId,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    LeaveType? leaveType,
    String? reason,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfDays,
    LeaveStatus? status,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return LeaveRequestModel(
      leaveId: leaveId ?? this.leaveId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      leaveType: leaveType ?? this.leaveType,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
