import 'package:cloud_firestore/cloud_firestore.dart';

enum EventCategory {
  sports,
  academic,
  cultural,
  meeting,
  holiday,
  other,
}

class EventModel {
  final String eventId;
  final String title;
  final String? description;
  final EventCategory category;
  final String? location;
  final DateTime eventDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? organizerId;
  final String? organizerName;
  final List<String>? targetAudience; // classIds or 'all'
  final List<String>? attachmentUrls;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  EventModel({
    required this.eventId,
    required this.title,
    this.description,
    required this.category,
    this.location,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.organizerId,
    this.organizerName,
    this.targetAudience,
    this.attachmentUrls,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get categoryString {
    switch (category) {
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.meeting:
        return 'Meeting';
      case EventCategory.holiday:
        return 'Holiday';
      case EventCategory.other:
        return 'Other';
    }
  }

  factory EventModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      category: _categoryFromString(data['category'] ?? 'Other'),
      location: data['location'],
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      organizerId: data['organizerId'],
      organizerName: data['organizerName'],
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static EventCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return EventCategory.sports;
      case 'academic':
        return EventCategory.academic;
      case 'cultural':
        return EventCategory.cultural;
      case 'meeting':
        return EventCategory.meeting;
      case 'holiday':
        return EventCategory.holiday;
      default:
        return EventCategory.other;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'category': categoryString,
      'location': location,
      'eventDate': Timestamp.fromDate(eventDate),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'targetAudience': targetAudience,
      'attachmentUrls': attachmentUrls,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  EventModel copyWith({
    String? eventId,
    String? title,
    String? description,
    EventCategory? category,
    String? location,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    String? organizerId,
    String? organizerName,
    List<String>? targetAudience,
    List<String>? attachmentUrls,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      targetAudience: targetAudience ?? this.targetAudience,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
