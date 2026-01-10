import 'package:cloud_firestore/cloud_firestore.dart';

enum NoticeType {
  urgent,
  academic,
  event,
  holiday,
  admin,
  general,
}

class NoticeModel {
  final String noticeId;
  final String title;
  final String description;
  final NoticeType noticeType;
  final String? targetAudience; // 'all', 'students', 'teachers', 'parents', or classId
  final String? createdBy;
  final String? createdByName;
  final List<String>? attachmentUrls;
  final DateTime? expiryDate;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  NoticeModel({
    required this.noticeId,
    required this.title,
    required this.description,
    required this.noticeType,
    this.targetAudience,
    this.createdBy,
    this.createdByName,
    this.attachmentUrls,
    this.expiryDate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get noticeTypeString {
    switch (noticeType) {
      case NoticeType.urgent:
        return 'URGENT';
      case NoticeType.academic:
        return 'ACADEMIC';
      case NoticeType.event:
        return 'EVENT';
      case NoticeType.holiday:
        return 'HOLIDAY';
      case NoticeType.admin:
        return 'ADMIN';
      case NoticeType.general:
        return 'GENERAL';
    }
  }

  factory NoticeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoticeModel(
      noticeId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      noticeType: _typeFromString(data['noticeType'] ?? 'General'),
      targetAudience: data['targetAudience'],
      createdBy: data['createdBy'],
      createdByName: data['createdByName'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static NoticeType _typeFromString(String type) {
    switch (type.toUpperCase()) {
      case 'URGENT':
        return NoticeType.urgent;
      case 'ACADEMIC':
        return NoticeType.academic;
      case 'EVENT':
        return NoticeType.event;
      case 'HOLIDAY':
        return NoticeType.holiday;
      case 'ADMIN':
        return NoticeType.admin;
      default:
        return NoticeType.general;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'noticeId': noticeId,
      'title': title,
      'description': description,
      'noticeType': noticeTypeString,
      'targetAudience': targetAudience,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'attachmentUrls': attachmentUrls,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  NoticeModel copyWith({
    String? noticeId,
    String? title,
    String? description,
    NoticeType? noticeType,
    String? targetAudience,
    String? createdBy,
    String? createdByName,
    List<String>? attachmentUrls,
    DateTime? expiryDate,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return NoticeModel(
      noticeId: noticeId ?? this.noticeId,
      title: title ?? this.title,
      description: description ?? this.description,
      noticeType: noticeType ?? this.noticeType,
      targetAudience: targetAudience ?? this.targetAudience,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
