import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus {
  submitted,
  late,
  graded,
  returned,
}

class HomeworkSubmissionModel {
  final String submissionId;
  final String homeworkId;
  final String studentId;
  final String studentName;
  final String? submissionText;
  final List<String>? attachmentUrls;
  final SubmissionStatus status;
  final DateTime? submittedAt;
  final int? marksObtained;
  final int? maxMarks;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  HomeworkSubmissionModel({
    required this.submissionId,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    this.submissionText,
    this.attachmentUrls,
    required this.status,
    this.submittedAt,
    this.marksObtained,
    this.maxMarks,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    required this.createdAt,
    this.updatedAt,
  });

  String get statusString {
    switch (status) {
      case SubmissionStatus.submitted:
        return 'Submitted';
      case SubmissionStatus.late:
        return 'Late';
      case SubmissionStatus.graded:
        return 'Graded';
      case SubmissionStatus.returned:
        return 'Returned';
    }
  }

  bool get isGraded => status == SubmissionStatus.graded || status == SubmissionStatus.returned;

  factory HomeworkSubmissionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeworkSubmissionModel(
      submissionId: doc.id,
      homeworkId: data['homeworkId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      submissionText: data['submissionText'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      status: _statusFromString(data['status'] ?? 'Submitted'),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      marksObtained: data['marksObtained'],
      maxMarks: data['maxMarks'],
      feedback: data['feedback'],
      gradedBy: data['gradedBy'],
      gradedAt: (data['gradedAt'] as Timestamp?)?.toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static SubmissionStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'late':
        return SubmissionStatus.late;
      case 'graded':
        return SubmissionStatus.graded;
      case 'returned':
        return SubmissionStatus.returned;
      default:
        return SubmissionStatus.submitted;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'homeworkId': homeworkId,
      'studentId': studentId,
      'studentName': studentName,
      'submissionText': submissionText,
      'attachmentUrls': attachmentUrls,
      'status': statusString,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'feedback': feedback,
      'gradedBy': gradedBy,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  HomeworkSubmissionModel copyWith({
    String? submissionId,
    String? homeworkId,
    String? studentId,
    String? studentName,
    String? submissionText,
    List<String>? attachmentUrls,
    SubmissionStatus? status,
    DateTime? submittedAt,
    int? marksObtained,
    int? maxMarks,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return HomeworkSubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submissionText: submissionText ?? this.submissionText,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      marksObtained: marksObtained ?? this.marksObtained,
      maxMarks: maxMarks ?? this.maxMarks,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
