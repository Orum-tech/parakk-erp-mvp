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
    String? parentEmail,
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
        parentEmail: parentEmail,
      );

      await _firestore.collection('users').doc(user.uid).update(studentModel.toMap());

      // If parentEmail is provided, check if parent already exists and link immediately
      if (parentEmail != null && parentEmail.isNotEmpty && parentId == null) {
        await _linkStudentToExistingParent(user.uid, parentEmail, parentName);
      }
    } catch (e) {
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  // Save teacher onboarding data
  Future<void> completeTeacherOnboarding({
    required String employeeId,
    required List<String> subjects,
    required List<String> classIds,
    String? classTeacherClassId,
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
        classTeacherClassId: classTeacherClassId,
        department: department,
        qualification: qualification,
        yearsOfExperience: yearsOfExperience,
        joiningDate: joiningDate,
        specialization: specialization,
      );

      // Update teacher document
      await _firestore.collection('users').doc(user.uid).update(teacherModel.toMap());

      // Update class document to set class teacher (only one class can have this teacher as class teacher)
      if (classTeacherClassId != null && classTeacherClassId.isNotEmpty) {
        final teacherName = userDoc.data()!['name'] ?? '';
        
        // Parse classId to get className and section (format: class_5_A)
        final parts = classTeacherClassId.replaceFirst('class_', '').split('_');
        if (parts.length == 2) {
          final className = 'Class ${parts[0]}';
          final section = parts[1];
          
          // Check if class document exists
          final classRef = _firestore.collection('classes').doc(classTeacherClassId);
          final classDoc = await classRef.get();
          
          final updateData = <String, dynamic>{
            'classId': classTeacherClassId,
            'className': className,
            'section': section,
            'classTeacherId': user.uid,
            'classTeacherName': teacherName,
            'updatedAt': Timestamp.now(),
          };
          
          // Only set createdAt if document doesn't exist
          if (!classDoc.exists) {
            updateData['createdAt'] = Timestamp.now();
          }
          
          await classRef.set(updateData, SetOptions(merge: true));
          
          // Clear class teacher from any other classes that might have this teacher assigned
          // (in case teacher was previously assigned to a different class)
          final otherClassesQuery = await _firestore
              .collection('classes')
              .where('classTeacherId', isEqualTo: user.uid)
              .get();
          
          final batch = _firestore.batch();
          for (var doc in otherClassesQuery.docs) {
            if (doc.id != classTeacherClassId) {
              batch.update(doc.reference, {
                'classTeacherId': null,
                'classTeacherName': null,
                'updatedAt': Timestamp.now(),
              });
            }
          }
          if (otherClassesQuery.docs.isNotEmpty) {
            await batch.commit();
          }
        }
      }
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

  // Link student to existing parent if parent already signed up
  Future<void> _linkStudentToExistingParent(
    String studentId,
    String parentEmail,
    String? parentName,
  ) async {
    try {
      // Find parent with matching email
      final parentQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .where('email', isEqualTo: parentEmail.toLowerCase())
          .limit(1)
          .get();

      if (parentQuery.docs.isEmpty) {
        // Try lowercase 'parent' as fallback
        final fallbackQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'parent')
            .where('email', isEqualTo: parentEmail.toLowerCase())
            .limit(1)
            .get();

        if (fallbackQuery.docs.isEmpty) return;

        final parentDoc = fallbackQuery.docs.first;
        final parentId = parentDoc.id;
        final parentData = parentDoc.data();
        final actualParentName = parentName ?? parentData['name'] ?? '';

        // Update student with parent info
        await _firestore.collection('users').doc(studentId).update({
          'parentId': parentId,
          'parentName': actualParentName,
        });
        return;
      }

      final parentDoc = parentQuery.docs.first;
      final parentId = parentDoc.id;
      final parentData = parentDoc.data();
      final actualParentName = parentName ?? parentData['name'] ?? '';

      // Update student with parent info
      await _firestore.collection('users').doc(studentId).update({
        'parentId': parentId,
        'parentName': actualParentName,
      });
    } catch (e) {
      // Silently fail - linking is not critical for onboarding
      print('Error linking student to existing parent: $e');
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
