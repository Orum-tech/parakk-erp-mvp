import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email, password, name, and role
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
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
        createdAt: Timestamp.now(),
      );

      // Save user to Firestore
      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      // If parent signs up, auto-link to students with matching parentEmail
      if (role == UserRole.parent) {
        await _linkParentToStudents(uid, email.trim().toLowerCase());
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
        return UserModel.fromDocument(doc);
      } else {
        throw Exception('User data not found');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
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

  // Auto-link parent to students with matching email
  Future<void> _linkParentToStudents(String parentId, String parentEmail) async {
    try {
      // Find all students with matching parentEmail
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('parentEmail', isEqualTo: parentEmail)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        // Try lowercase 'student' as fallback
        final fallbackSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
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

