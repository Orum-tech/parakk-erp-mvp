import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_admin_model.dart';

class SchoolAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create school admin
  Future<SchoolAdminModel> createSchoolAdmin({
    required String uid,
    required String name,
    required String email,
    required String schoolId,
    AdminRole adminRole = AdminRole.admin,
    String? employeeId,
    String? phoneNumber,
    List<String>? permissions,
    DateTime? joiningDate,
    String? profilePictureUrl,
  }) async {
    try {
      final admin = SchoolAdminModel(
        uid: uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        schoolId: schoolId,
        adminId: uid,
        adminRole: adminRole,
        employeeId: employeeId,
        phoneNumber: phoneNumber,
        permissions: permissions,
        joiningDate: joiningDate ?? DateTime.now(),
        profilePictureUrl: profilePictureUrl,
        createdAt: Timestamp.now(),
      );

      // Save to users collection
      await _firestore.collection('users').doc(uid).set(admin.toMap());

      return admin;
    } catch (e) {
      throw Exception('Failed to create school admin: $e');
    }
  }

  // Get school admin by ID
  Future<SchoolAdminModel?> getSchoolAdminById(String adminId) async {
    try {
      final doc = await _firestore.collection('users').doc(adminId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;
        final roleLower = role?.toLowerCase();
        
        if (roleLower == 'schooladmin' || roleLower == 'superadmin') {
          return SchoolAdminModel.fromDocument(doc);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get school admin: $e');
    }
  }

  // Get all admins for a school
  Future<List<SchoolAdminModel>> getSchoolAdmins(String schoolId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('schoolId', isEqualTo: schoolId)
          .where('role', whereIn: ['SchoolAdmin', 'schoolAdmin'])
          .get();

      return querySnapshot.docs
          .map((doc) => SchoolAdminModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get school admins: $e');
    }
  }

  // Update admin role
  Future<void> updateAdminRole(
    String adminId,
    AdminRole newRole, {
    List<String>? permissions,
  }) async {
    try {
      final updates = <String, dynamic>{
        'adminRole': _adminRoleToString(newRole),
      };

      if (permissions != null) {
        updates['permissions'] = permissions;
      }

      await _firestore.collection('users').doc(adminId).update(updates);
    } catch (e) {
      throw Exception('Failed to update admin role: $e');
    }
  }

  // Update admin permissions
  Future<void> updateAdminPermissions(
    String adminId,
    List<String> permissions,
  ) async {
    try {
      await _firestore.collection('users').doc(adminId).update({
        'permissions': permissions,
      });
    } catch (e) {
      throw Exception('Failed to update admin permissions: $e');
    }
  }

  // Check if user is school admin
  Future<bool> isSchoolAdmin(String userId, String schoolId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String?;
      final roleLower = role?.toLowerCase();
      final userSchoolId = data['schoolId'] as String?;

      return (roleLower == 'schooladmin' || roleLower == 'superadmin') &&
          userSchoolId == schoolId;
    } catch (e) {
      return false;
    }
  }

  // Check if user is super admin
  Future<bool> isSuperAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String?;

      return role?.toLowerCase() == 'superadmin';
    } catch (e) {
      return false;
    }
  }

  // Check if admin has permission
  Future<bool> hasPermission(String adminId, String permission) async {
    try {
      final admin = await getSchoolAdminById(adminId);
      if (admin == null) return false;

      return admin.hasPermission(permission);
    } catch (e) {
      return false;
    }
  }

  // Stream school admins
  Stream<List<SchoolAdminModel>> streamSchoolAdmins(String schoolId) {
    return _firestore
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('role', whereIn: ['SchoolAdmin', 'schoolAdmin'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolAdminModel.fromDocument(doc))
            .toList());
  }

  // Remove admin (soft delete by setting isActive to false)
  Future<void> removeAdmin(String adminId) async {
    try {
      await _firestore.collection('users').doc(adminId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }

  // Restore admin
  Future<void> restoreAdmin(String adminId) async {
    try {
      await _firestore.collection('users').doc(adminId).update({
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to restore admin: $e');
    }
  }

  String _adminRoleToString(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'superAdmin';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.subAdmin:
        return 'subAdmin';
    }
  }
}
