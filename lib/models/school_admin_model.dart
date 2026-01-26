import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum AdminRole {
  superAdmin, // Full access
  admin, // Manage users, classes, settings
  subAdmin, // Limited access (e.g., only students)
}

class SchoolAdminModel extends UserModel {
  final String? adminId;
  final String? employeeId;
  final String? phoneNumber;
  final AdminRole adminRole;
  final List<String>? permissions;
  final DateTime? joiningDate;

  SchoolAdminModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.schoolId,
    required super.createdAt,
    this.adminId,
    this.employeeId,
    this.phoneNumber,
    required this.adminRole,
    this.permissions,
    this.joiningDate,
    super.profilePictureUrl,
  }) : super(role: UserRole.schoolAdmin);

  // Convert admin role enum to string for Firestore
  String get adminRoleString {
    switch (adminRole) {
      case AdminRole.superAdmin:
        return 'superAdmin';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.subAdmin:
        return 'subAdmin';
    }
  }

  // Check if admin has specific permission
  bool hasPermission(String permission) {
    if (adminRole == AdminRole.superAdmin) return true;
    return permissions?.contains(permission) ?? false;
  }

  // Create SchoolAdminModel from Firestore document
  factory SchoolAdminModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolAdminModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      schoolId: data['schoolId'] ?? '',
      adminId: data['adminId'] ?? doc.id,
      employeeId: data['employeeId'],
      phoneNumber: data['phoneNumber'],
      adminRole: _adminRoleFromString(data['adminRole'] ?? 'admin'),
      permissions: data['permissions'] != null
          ? List<String>.from(data['permissions'])
          : null,
      joiningDate: (data['joiningDate'] as Timestamp?)?.toDate(),
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'adminId': adminId ?? uid,
      'schoolId': schoolId,
      'employeeId': employeeId,
      'phoneNumber': phoneNumber,
      'adminRole': adminRoleString,
      'permissions': permissions,
      'joiningDate': joiningDate != null ? Timestamp.fromDate(joiningDate!) : null,
    });
    return map;
  }

  // Parse admin role string to enum
  static AdminRole _adminRoleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return AdminRole.superAdmin;
      case 'admin':
        return AdminRole.admin;
      case 'subadmin':
        return AdminRole.subAdmin;
      default:
        return AdminRole.admin;
    }
  }

  SchoolAdminModel copyWith({
    String? uid,
    String? name,
    String? email,
    Timestamp? createdAt,
    String? adminId,
    String? schoolId,
    String? employeeId,
    String? phoneNumber,
    AdminRole? adminRole,
    List<String>? permissions,
    DateTime? joiningDate,
    String? profilePictureUrl,
  }) {
    return SchoolAdminModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      schoolId: schoolId ?? this.schoolId,
      adminId: adminId ?? this.adminId,
      employeeId: employeeId ?? this.employeeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      adminRole: adminRole ?? this.adminRole,
      permissions: permissions ?? this.permissions,
      joiningDate: joiningDate ?? this.joiningDate,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
