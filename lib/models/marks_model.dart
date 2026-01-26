import 'package:cloud_firestore/cloud_firestore.dart';

class MarksModel {
  final String marksId;
  final String schoolId; // REQUIRED - links marks to school
  final String examId;
  final String examName;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final int marksObtained;
  final int maxMarks;
  final String? grade;
  final String? remarks;
  final String? enteredBy;
  final String? enteredByName;
  final DateTime? examDate;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  MarksModel({
    required this.marksId,
    required this.schoolId,
    required this.examId,
    required this.examName,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.marksObtained,
    required this.maxMarks,
    this.grade,
    this.remarks,
    this.enteredBy,
    this.enteredByName,
    this.examDate,
    required this.createdAt,
    this.updatedAt,
  });

  double get percentage => (marksObtained / maxMarks) * 100;
  bool get isPassing => passingMarks != null ? marksObtained >= passingMarks! : percentage >= 40;
  int? get passingMarks => (maxMarks * 0.4).round();

  String calculateGrade() {
    final pct = percentage;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C+';
    if (pct >= 40) return 'C';
    return 'F';
  }

  factory MarksModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MarksModel(
      marksId: doc.id,
      schoolId: data['schoolId'] ?? '', // Will be required after migration
      examId: data['examId'] ?? '',
      examName: data['examName'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      marksObtained: data['marksObtained'] ?? 0,
      maxMarks: data['maxMarks'] ?? 100,
      grade: data['grade'],
      remarks: data['remarks'],
      enteredBy: data['enteredBy'],
      enteredByName: data['enteredByName'],
      examDate: (data['examDate'] as Timestamp?)?.toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    final calculatedGrade = grade ?? calculateGrade();
    return {
      'marksId': marksId,
      'schoolId': schoolId,
      'examId': examId,
      'examName': examName,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'grade': calculatedGrade,
      'remarks': remarks,
      'enteredBy': enteredBy,
      'enteredByName': enteredByName,
      'examDate': examDate != null ? Timestamp.fromDate(examDate!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  MarksModel copyWith({
    String? marksId,
    String? schoolId,
    String? examId,
    String? examName,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    int? marksObtained,
    int? maxMarks,
    String? grade,
    String? remarks,
    String? enteredBy,
    String? enteredByName,
    DateTime? examDate,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MarksModel(
      marksId: marksId ?? this.marksId,
      schoolId: schoolId ?? this.schoolId,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      marksObtained: marksObtained ?? this.marksObtained,
      maxMarks: maxMarks ?? this.maxMarks,
      grade: grade ?? this.grade,
      remarks: remarks ?? this.remarks,
      enteredBy: enteredBy ?? this.enteredBy,
      enteredByName: enteredByName ?? this.enteredByName,
      examDate: examDate ?? this.examDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
