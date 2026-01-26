import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  teacher,
  parent,
  schoolAdmin,
  superAdmin,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String schoolId; // REQUIRED - links user to school
  final bool isActive; // For soft deletion
  final Timestamp createdAt;
  final String? profilePictureUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.schoolId,
    this.isActive = true,
    required this.createdAt,
    this.profilePictureUrl,
  });

  // Convert role enum to string for Firestore
  String get roleString {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.parent:
        return 'Parent';
      case UserRole.schoolAdmin:
        return 'SchoolAdmin';
      case UserRole.superAdmin:
        return 'SuperAdmin';
    }
  }

  // Create UserModel from Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: _roleFromString(data['role'] ?? 'Student'),
      schoolId: data['schoolId'] ?? '', // Will be required after migration
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': roleString,
      'schoolId': schoolId,
      'isActive': isActive,
      'createdAt': createdAt,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  // Parse role string to enum
  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
        return UserRole.parent;
      case 'schooladmin':
        return UserRole.schoolAdmin;
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        return UserRole.student;
    }
  }

  // Get dashboard route based on role
  String get dashboardRoute {
    switch (role) {
      case UserRole.student:
        return '/student-dashboard';
      case UserRole.teacher:
        return '/teacher-dashboard';
      case UserRole.parent:
        return '/parent-dashboard';
      case UserRole.schoolAdmin:
        return '/school-admin-dashboard';
      case UserRole.superAdmin:
        return '/super-admin-dashboard';
    }
  }
}

