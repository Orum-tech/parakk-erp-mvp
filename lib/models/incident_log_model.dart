import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentSeverity {
  minor,
  moderate,
  severe,
}

enum IncidentStatus {
  pending,
  underReview,
  actionTaken,
  resolved,
}

class IncidentLogModel {
  final String incidentId;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String issue;
  final String description;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String? reportedBy;
  final String? reportedByName;
  final String? actionTaken;
  final DateTime incidentDate;
  final DateTime? resolvedDate;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  IncidentLogModel({
    required this.incidentId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.issue,
    required this.description,
    required this.severity,
    required this.status,
    this.reportedBy,
    this.reportedByName,
    this.actionTaken,
    required this.incidentDate,
    this.resolvedDate,
    required this.createdAt,
    this.updatedAt,
  });

  String get severityString {
    switch (severity) {
      case IncidentSeverity.minor:
        return 'Minor';
      case IncidentSeverity.moderate:
        return 'Moderate';
      case IncidentSeverity.severe:
        return 'Severe';
    }
  }

  String get statusString {
    switch (status) {
      case IncidentStatus.pending:
        return 'Pending';
      case IncidentStatus.underReview:
        return 'Under Review';
      case IncidentStatus.actionTaken:
        return 'Action Taken';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  factory IncidentLogModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncidentLogModel(
      incidentId: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      issue: data['issue'] ?? '',
      description: data['description'] ?? '',
      severity: _severityFromString(data['severity'] ?? 'Minor'),
      status: _statusFromString(data['status'] ?? 'Pending'),
      reportedBy: data['reportedBy'],
      reportedByName: data['reportedByName'],
      actionTaken: data['actionTaken'],
      incidentDate: (data['incidentDate'] as Timestamp).toDate(),
      resolvedDate: (data['resolvedDate'] as Timestamp?)?.toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static IncidentSeverity _severityFromString(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return IncidentSeverity.severe;
      case 'moderate':
        return IncidentSeverity.moderate;
      default:
        return IncidentSeverity.minor;
    }
  }

  static IncidentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return IncidentStatus.resolved;
      case 'actiontaken':
      case 'action taken':
        return IncidentStatus.actionTaken;
      case 'underreview':
      case 'under review':
        return IncidentStatus.underReview;
      default:
        return IncidentStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'issue': issue,
      'description': description,
      'severity': severityString,
      'status': statusString,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'actionTaken': actionTaken,
      'incidentDate': Timestamp.fromDate(incidentDate),
      'resolvedDate': resolvedDate != null ? Timestamp.fromDate(resolvedDate!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  IncidentLogModel copyWith({
    String? incidentId,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    String? issue,
    String? description,
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? reportedBy,
    String? reportedByName,
    String? actionTaken,
    DateTime? incidentDate,
    DateTime? resolvedDate,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return IncidentLogModel(
      incidentId: incidentId ?? this.incidentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      issue: issue ?? this.issue,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      actionTaken: actionTaken ?? this.actionTaken,
      incidentDate: incidentDate ?? this.incidentDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
