import 'package:cloud_firestore/cloud_firestore.dart';

enum ResourceCategory {
  textbook,
  journal,
  examPrep,
  fiction,
  reference,
  other,
}

class LibraryResourceModel {
  final String resourceId;
  final String title;
  final String? author;
  final String? isbn;
  final ResourceCategory category;
  final String? description;
  final String? coverImageUrl;
  final String? fileUrl;
  final String? fileType; // pdf, epub, etc.
  final int? totalPages;
  final String? classId;
  final String? className;
  final String? subjectId;
  final String? subjectName;
  final int? totalCopies;
  final int? availableCopies;
  final int? downloadCount;
  final bool isAvailable;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  LibraryResourceModel({
    required this.resourceId,
    required this.title,
    this.author,
    this.isbn,
    required this.category,
    this.description,
    this.coverImageUrl,
    this.fileUrl,
    this.fileType,
    this.totalPages,
    this.classId,
    this.className,
    this.subjectId,
    this.subjectName,
    this.totalCopies,
    this.availableCopies,
    this.isAvailable = true,
    this.downloadCount,
    required this.createdAt,
    this.updatedAt,
  });

  String get categoryString {
    switch (category) {
      case ResourceCategory.textbook:
        return 'Textbook';
      case ResourceCategory.journal:
        return 'Journal';
      case ResourceCategory.examPrep:
        return 'Exam Prep';
      case ResourceCategory.fiction:
        return 'Fiction';
      case ResourceCategory.reference:
        return 'Reference';
      case ResourceCategory.other:
        return 'Other';
    }
  }

  factory LibraryResourceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LibraryResourceModel(
      resourceId: doc.id,
      title: data['title'] ?? '',
      author: data['author'],
      isbn: data['isbn'],
      category: _categoryFromString(data['category'] ?? 'Other'),
      description: data['description'],
      coverImageUrl: data['coverImageUrl'],
      fileUrl: data['fileUrl'],
      fileType: data['fileType'],
      totalPages: data['totalPages'],
      classId: data['classId'],
      className: data['className'],
      subjectId: data['subjectId'],
      subjectName: data['subjectName'],
      totalCopies: data['totalCopies'],
      availableCopies: data['availableCopies'],
      downloadCount: data['downloadCount'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static ResourceCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'textbook':
        return ResourceCategory.textbook;
      case 'journal':
        return ResourceCategory.journal;
      case 'examprep':
      case 'exam prep':
        return ResourceCategory.examPrep;
      case 'fiction':
        return ResourceCategory.fiction;
      case 'reference':
        return ResourceCategory.reference;
      default:
        return ResourceCategory.other;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'category': categoryString,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'totalPages': totalPages,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'downloadCount': downloadCount ?? 0,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  LibraryResourceModel copyWith({
    String? resourceId,
    String? title,
    String? author,
    String? isbn,
    ResourceCategory? category,
    String? description,
    String? coverImageUrl,
    String? fileUrl,
    String? fileType,
    int? totalPages,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    int? totalCopies,
    int? availableCopies,
    int? downloadCount,
    bool? isAvailable,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return LibraryResourceModel(
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      category: category ?? this.category,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      totalPages: totalPages ?? this.totalPages,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      downloadCount: downloadCount ?? this.downloadCount,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
