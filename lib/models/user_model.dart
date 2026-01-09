import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  teacher,
  parent,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
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
    }
  }

  // Create UserModel from Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: _roleFromString(data['role'] ?? 'Student'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': roleString,
      'createdAt': createdAt,
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
    }
  }
}

