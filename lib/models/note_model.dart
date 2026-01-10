import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String noteId;
  final String title;
  final String? description;
  final String subjectId;
  final String subjectName;
  final String? classId;
  final String? className;
  final String teacherId;
  final String teacherName;
  final String? chapterName;
  final List<String> attachmentUrls;
  final String? fileType; // pdf, docx, image, etc.
  final int? fileSize;
  final int? downloadCount;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  NoteModel({
    required this.noteId,
    required this.title,
    this.description,
    required this.subjectId,
    required this.subjectName,
    this.classId,
    this.className,
    required this.teacherId,
    required this.teacherName,
    this.chapterName,
    required this.attachmentUrls,
    this.fileType,
    this.fileSize,
    this.downloadCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory NoteModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      noteId: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      classId: data['classId'],
      className: data['className'],
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      chapterName: data['chapterName'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      fileType: data['fileType'],
      fileSize: data['fileSize'],
      downloadCount: data['downloadCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'chapterName': chapterName,
      'attachmentUrls': attachmentUrls,
      'fileType': fileType,
      'fileSize': fileSize,
      'downloadCount': downloadCount ?? 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  NoteModel copyWith({
    String? noteId,
    String? title,
    String? description,
    String? subjectId,
    String? subjectName,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    String? chapterName,
    List<String>? attachmentUrls,
    String? fileType,
    int? fileSize,
    int? downloadCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return NoteModel(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      chapterName: chapterName ?? this.chapterName,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      downloadCount: downloadCount ?? this.downloadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
