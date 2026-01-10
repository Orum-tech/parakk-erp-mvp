import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';

class OnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user has completed onboarding
  Future<bool> isOnboardingComplete(String uid, String role) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      
      if (role == 'Student') {
        return data['classId'] != null && data['rollNumber'] != null;
      } else if (role == 'Teacher') {
        return data['employeeId'] != null && data['subjects'] != null && (data['subjects'] as List).isNotEmpty;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Save student onboarding data
  Future<void> completeStudentOnboarding({
    required String rollNumber,
    required String classId,
    required String className,
    required String section,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? emergencyContact,
    String? parentId,
    String? parentName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User document not found');

      final studentModel = StudentModel(
        uid: user.uid,
        name: userDoc.data()!['name'] ?? '',
        email: userDoc.data()!['email'] ?? '',
        createdAt: userDoc.data()!['createdAt'] ?? Timestamp.now(),
        studentId: user.uid,
        rollNumber: rollNumber,
        classId: classId,
        className: className,
        section: section,
        phoneNumber: phoneNumber,
        address: address,
        dateOfBirth: dateOfBirth,
        bloodGroup: bloodGroup,
        emergencyContact: emergencyContact,
        parentId: parentId,
        parentName: parentName,
      );

      await _firestore.collection('users').doc(user.uid).update(studentModel.toMap());
    } catch (e) {
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  // Save teacher onboarding data
  Future<void> completeTeacherOnboarding({
    required String employeeId,
    required List<String> subjects,
    required List<String> classIds,
    String? phoneNumber,
    String? address,
    String? department,
    String? qualification,
    int? yearsOfExperience,
    DateTime? joiningDate,
    String? specialization,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User document not found');

      final teacherModel = TeacherModel(
        uid: user.uid,
        name: userDoc.data()!['name'] ?? '',
        email: userDoc.data()!['email'] ?? '',
        createdAt: userDoc.data()!['createdAt'] ?? Timestamp.now(),
        teacherId: user.uid,
        employeeId: employeeId,
        phoneNumber: phoneNumber,
        address: address,
        subjects: subjects,
        classIds: classIds,
        department: department,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        joiningDate: joiningDate,
        specialization: specialization,
      );

      await _firestore.collection('users').doc(user.uid).update(teacherModel.toMap());
    } catch (e) {
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  // Fetch all classes for dropdown
  Future<List<ClassOption>> fetchClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ClassOption(
          classId: doc.id,
          className: data['className'] ?? '',
          section: data['section'] ?? '',
          fullName: '${data['className'] ?? ''}-${data['section'] ?? ''}',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch all subjects for dropdown
  Future<List<SubjectOption>> fetchSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SubjectOption(
          subjectId: doc.id,
          subjectName: data['subjectName'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

class ClassOption {
  final String classId;
  final String className;
  final String section;
  final String fullName;

  ClassOption({
    required this.classId,
    required this.className,
    required this.section,
    required this.fullName,
  });
}

class SubjectOption {
  final String subjectId;
  final String subjectName;

  SubjectOption({
    required this.subjectId,
    required this.subjectName,
  });
}
