import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus {
  trial,
  active,
  expired,
  suspended,
  cancelled,
}

class SchoolModel {
  final String schoolId;
  final String schoolName;
  final String schoolCode; // Unique identifier (e.g., "SCH001")
  final String email;
  final String phoneNumber;
  final String address;
  final String? logoUrl;
  final String? website;
  final String? principalName;
  final String? principalEmail;
  final String? principalPhone;
  final SubscriptionStatus subscriptionStatus;
  final DateTime subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final int maxStudents;
  final int maxTeachers;
  final int currentStudents;
  final int currentTeachers;
  final Map<String, dynamic>? settings; // School-specific settings
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? createdBy; // Admin who created the school

  SchoolModel({
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.logoUrl,
    this.website,
    this.principalName,
    this.principalEmail,
    this.principalPhone,
    required this.subscriptionStatus,
    required this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.maxStudents,
    required this.maxTeachers,
    this.currentStudents = 0,
    this.currentTeachers = 0,
    this.settings,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  // Convert subscription status enum to string for Firestore
  String get subscriptionStatusString {
    switch (subscriptionStatus) {
      case SubscriptionStatus.trial:
        return 'trial';
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.suspended:
        return 'suspended';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
    }
  }

  // Check if subscription is active
  bool get isSubscriptionActive {
    return subscriptionStatus == SubscriptionStatus.active ||
        subscriptionStatus == SubscriptionStatus.trial;
  }

  // Check if subscription is expired
  bool get isSubscriptionExpired {
    if (subscriptionEndDate == null) return false;
    return DateTime.now().isAfter(subscriptionEndDate!) &&
        subscriptionStatus != SubscriptionStatus.cancelled;
  }

  // Create SchoolModel from Firestore document
  factory SchoolModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolModel(
      schoolId: doc.id,
      schoolName: data['schoolName'] ?? '',
      schoolCode: data['schoolCode'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      logoUrl: data['logoUrl'],
      website: data['website'],
      principalName: data['principalName'],
      principalEmail: data['principalEmail'],
      principalPhone: data['principalPhone'],
      subscriptionStatus: _subscriptionStatusFromString(
        data['subscriptionStatus'] ?? 'trial',
      ),
      subscriptionStartDate: (data['subscriptionStartDate'] as Timestamp)
          .toDate(),
      subscriptionEndDate: (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      maxStudents: data['maxStudents'] ?? 1000,
      maxTeachers: data['maxTeachers'] ?? 100,
      currentStudents: data['currentStudents'] ?? 0,
      currentTeachers: data['currentTeachers'] ?? 0,
      settings: data['settings'] != null
          ? Map<String, dynamic>.from(data['settings'])
          : null,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      createdBy: data['createdBy'],
    );
  }

  // Convert SchoolModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'schoolCode': schoolCode,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'logoUrl': logoUrl,
      'website': website,
      'principalName': principalName,
      'principalEmail': principalEmail,
      'principalPhone': principalPhone,
      'subscriptionStatus': subscriptionStatusString,
      'subscriptionStartDate': Timestamp.fromDate(subscriptionStartDate),
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'maxStudents': maxStudents,
      'maxTeachers': maxTeachers,
      'currentStudents': currentStudents,
      'currentTeachers': currentTeachers,
      'settings': settings,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'createdBy': createdBy,
    };
  }

  // Parse subscription status string to enum
  static SubscriptionStatus _subscriptionStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'trial':
        return SubscriptionStatus.trial;
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'suspended':
        return SubscriptionStatus.suspended;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.trial;
    }
  }

  SchoolModel copyWith({
    String? schoolId,
    String? schoolName,
    String? schoolCode,
    String? email,
    String? phoneNumber,
    String? address,
    String? logoUrl,
    String? website,
    String? principalName,
    String? principalEmail,
    String? principalPhone,
    SubscriptionStatus? subscriptionStatus,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    int? maxStudents,
    int? maxTeachers,
    int? currentStudents,
    int? currentTeachers,
    Map<String, dynamic>? settings,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
  }) {
    return SchoolModel(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      schoolCode: schoolCode ?? this.schoolCode,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      principalName: principalName ?? this.principalName,
      principalEmail: principalEmail ?? this.principalEmail,
      principalPhone: principalPhone ?? this.principalPhone,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      currentStudents: currentStudents ?? this.currentStudents,
      currentTeachers: currentTeachers ?? this.currentTeachers,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
