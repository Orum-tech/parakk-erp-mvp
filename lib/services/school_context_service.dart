import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import 'school_service.dart';

class SchoolContextService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SchoolService _schoolService = SchoolService();

  String? _currentSchoolId;
  SchoolModel? _currentSchool;

  // Get current user's school
  Future<SchoolModel?> getCurrentSchool() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final schoolId = userData['schoolId'] as String?;

      if (schoolId == null || schoolId.isEmpty) return null;

      // Return cached school if same
      if (_currentSchoolId == schoolId && _currentSchool != null) {
        return _currentSchool;
      }

      // Fetch school
      final school = await _schoolService.getSchoolById(schoolId);
      if (school != null) {
        _currentSchoolId = schoolId;
        _currentSchool = school;
      }

      return school;
    } catch (e) {
      print('Error getting current school: $e');
      return null;
    }
  }

  // Get current school ID
  Future<String?> getCurrentSchoolId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['schoolId'] as String?;
    } catch (e) {
      print('Error getting current school ID: $e');
      return null;
    }
  }

  // Set school context (for multi-school admins)
  Future<void> setSchoolContext(String schoolId) async {
    try {
      // Verify school exists and is active
      final school = await _schoolService.getSchoolById(schoolId);
      if (school == null) {
        throw Exception('School not found');
      }

      if (!school.isSubscriptionActive) {
        throw Exception('School subscription is not active');
      }

      _currentSchoolId = schoolId;
      _currentSchool = school;
    } catch (e) {
      throw Exception('Failed to set school context: $e');
    }
  }

  // Verify school subscription is active
  Future<bool> isSchoolActive(String schoolId) async {
    return await _schoolService.isSchoolActive(schoolId);
  }

  // Check if user belongs to school
  Future<bool> verifyUserSchool(String userId, String schoolId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userSchoolId = userData['schoolId'] as String?;

      return userSchoolId == schoolId;
    } catch (e) {
      return false;
    }
  }

  // Verify current user belongs to school
  Future<bool> verifyCurrentUserSchool(String schoolId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      return await verifyUserSchool(user.uid, schoolId);
    } catch (e) {
      return false;
    }
  }

  // Check if current user's school is active
  Future<bool> isCurrentSchoolActive() async {
    try {
      final schoolId = await getCurrentSchoolId();
      if (schoolId == null) return false;

      return await isSchoolActive(schoolId);
    } catch (e) {
      return false;
    }
  }

  // Clear school context (on logout)
  void clearContext() {
    _currentSchoolId = null;
    _currentSchool = null;
  }

  // Stream current school
  Stream<SchoolModel?> streamCurrentSchool() {
    return Stream.fromFuture(getCurrentSchoolId()).asyncExpand((schoolId) {
      if (schoolId == null) {
        return Stream<SchoolModel?>.value(null);
      }
      return _schoolService.streamSchool(schoolId);
    });
  }

  // Get school for user ID
  Future<SchoolModel?> getSchoolForUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final schoolId = userData['schoolId'] as String?;

      if (schoolId == null || schoolId.isEmpty) return null;

      return await _schoolService.getSchoolById(schoolId);
    } catch (e) {
      print('Error getting school for user: $e');
      return null;
    }
  }
}
