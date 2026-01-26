import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'school_service.dart';
import 'school_context_service.dart';
import 'school_invitation_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SchoolService _schoolService = SchoolService();
  final SchoolContextService _schoolContextService = SchoolContextService();
  final SchoolInvitationService _invitationService = SchoolInvitationService();

  // Sign up with email, password, name, and role
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? schoolId,
    String? schoolCode,
    String? invitationId,
  }) async {
    try {
      String? finalSchoolId = schoolId;

      // Determine schoolId from invitation, schoolCode, or provided schoolId
      if (invitationId != null) {
        // Sign up via invitation
        final invitation = await _invitationService.getInvitationById(invitationId);
        if (invitation == null || !invitation.canAccept) {
          throw Exception('Invalid or expired invitation');
        }
        finalSchoolId = invitation.schoolId;
      } else if (schoolCode != null) {
        // Sign up with school code
        final school = await _schoolService.getSchoolByCode(schoolCode);
        if (school == null) {
          throw Exception('Invalid school code');
        }
        if (!school.isSubscriptionActive) {
          throw Exception('School subscription is not active');
        }
        finalSchoolId = school.schoolId;
      } else if (finalSchoolId == null || finalSchoolId.isEmpty) {
        // For superAdmin, schoolId can be empty
        if (role != UserRole.superAdmin) {
          throw Exception('School code or invitation is required');
        }
      }

      // Validate school if provided
      if (finalSchoolId != null && finalSchoolId.isNotEmpty) {
        final isActive = await _schoolService.isSchoolActive(finalSchoolId);
        if (!isActive) {
          throw Exception('School subscription is not active');
        }
      }

      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // Create user model
      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
        schoolId: finalSchoolId ?? '',
        isActive: true,
        createdAt: Timestamp.now(),
      );

      // Save user to Firestore
      try {
        await _firestore.collection('users').doc(uid).set(userModel.toMap());

        // Accept invitation if provided
        if (invitationId != null) {
          await _invitationService.acceptInvitation(invitationId, uid);
        }

        // Update school counts if schoolId is provided
        if (finalSchoolId != null && finalSchoolId.isNotEmpty) {
          if (role == UserRole.student) {
            await _schoolService.incrementStudentCount(finalSchoolId);
          } else if (role == UserRole.teacher) {
            await _schoolService.incrementTeacherCount(finalSchoolId);
          }
        }

        // If parent signs up, auto-link to students with matching parentEmail
        if (role == UserRole.parent && finalSchoolId != null && finalSchoolId.isNotEmpty) {
          await _linkParentToStudents(uid, email.trim().toLowerCase(), finalSchoolId);
        }
      } catch (e) {
        // Rollback: Delete the user from Auth if Firestore write fails
        await userCredential.user?.delete();
        throw Exception('Failed to create user profile. Please try again.');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Login with email and password
  Future<UserModel?> login({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final userModel = UserModel.fromDocument(doc);
        
        // Check if user is active
        if (!userModel.isActive) {
          await _auth.signOut();
          throw Exception('Your account has been deactivated. Please contact your school administrator.');
        }
        
        // Validate role if expectedRole is provided
        if (expectedRole != null && userModel.role != expectedRole) {
          // Sign out the user since role doesn't match
          await _auth.signOut();
          
          // Get the actual role string for error message
          final actualRoleString = userModel.roleString;
          final expectedRoleString = _roleToString(expectedRole);
          
          throw Exception('You are a $actualRoleString. Please change role and try to login as $actualRoleString.');
        }
        
        // Validate school subscription (except for superAdmin)
        if (userModel.role != UserRole.superAdmin && 
            userModel.schoolId.isNotEmpty) {
          final isActive = await _schoolService.isSchoolActive(userModel.schoolId);
          if (!isActive) {
            await _auth.signOut();
            throw Exception('Your school subscription is not active. Please contact your school administrator.');
          }
        }
        
        return userModel;
      } else {
        throw Exception('User data not found');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Helper method to convert UserRole enum to string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.parent:
        return 'Parent';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user with data
  Future<UserModel?> getCurrentUserWithData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  // Get auth state stream
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Auto-link parent to students with matching email (within same school)
  Future<void> _linkParentToStudents(
    String parentId,
    String parentEmail,
    String schoolId,
  ) async {
    try {
      // Find all students with matching parentEmail in the same school
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('schoolId', isEqualTo: schoolId)
          .where('parentEmail', isEqualTo: parentEmail)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        // Try lowercase 'student' as fallback
        final fallbackSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('schoolId', isEqualTo: schoolId)
            .where('parentEmail', isEqualTo: parentEmail)
            .get();

        if (fallbackSnapshot.docs.isEmpty) return;

        // Update all matching students
        final batch = _firestore.batch();
        final parentDoc = await _firestore.collection('users').doc(parentId).get();
        final parentName = parentDoc.data()?['name'] ?? '';

        for (var doc in fallbackSnapshot.docs) {
          batch.update(doc.reference, {
            'parentId': parentId,
            'parentName': parentName,
          });
        }
        await batch.commit();
        return;
      }

      // Update all matching students
      final batch = _firestore.batch();
      final parentDoc = await _firestore.collection('users').doc(parentId).get();
      final parentName = parentDoc.data()?['name'] ?? '';

      for (var doc in studentsSnapshot.docs) {
        batch.update(doc.reference, {
          'parentId': parentId,
          'parentName': parentName,
        });
      }
      await batch.commit();
    } catch (e) {
      // Silently fail - linking is not critical for signup
      print('Error linking parent to students: $e');
    }
  }

  // Validate school code
  Future<bool> validateSchoolCode(String schoolCode) async {
    try {
      final school = await _schoolService.getSchoolByCode(schoolCode);
      if (school == null) return false;
      return school.isSubscriptionActive;
    } catch (e) {
      return false;
    }
  }

  // Get pending invitations for email
  Future<List<dynamic>> getPendingInvitations(String email) async {
    try {
      return await _invitationService.getPendingInvitationsForEmail(email);
    } catch (e) {
      return [];
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'operation-not-allowed':
        return 'Email/password sign up is not enabled.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid login credentials.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }
}

