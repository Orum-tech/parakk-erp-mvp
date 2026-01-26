import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new school
  Future<SchoolModel> createSchool({
    required String schoolName,
    required String email,
    required String phoneNumber,
    required String address,
    String? logoUrl,
    String? website,
    String? principalName,
    String? principalEmail,
    String? principalPhone,
    int maxStudents = 1000,
    int maxTeachers = 100,
    String? createdBy,
  }) async {
    try {
      // Generate unique school code
      final schoolCode = await _generateSchoolCode();

      // Create school model
      final school = SchoolModel(
        schoolId: '', // Will be set by Firestore
        schoolName: schoolName.trim(),
        schoolCode: schoolCode,
        email: email.trim().toLowerCase(),
        phoneNumber: phoneNumber.trim(),
        address: address.trim(),
        logoUrl: logoUrl,
        website: website,
        principalName: principalName,
        principalEmail: principalEmail,
        principalPhone: principalPhone,
        subscriptionStatus: SubscriptionStatus.trial,
        subscriptionStartDate: DateTime.now(),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 30)), // 30-day trial
        maxStudents: maxStudents,
        maxTeachers: maxTeachers,
        currentStudents: 0,
        currentTeachers: 0,
        createdAt: Timestamp.now(),
        createdBy: createdBy,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('schools').add(school.toMap());
      
      // Update with the generated ID
      await docRef.update({'schoolId': docRef.id});
      
      return school.copyWith(schoolId: docRef.id);
    } catch (e) {
      throw Exception('Failed to create school: $e');
    }
  }

  // Get school by ID
  Future<SchoolModel?> getSchoolById(String schoolId) async {
    try {
      final doc = await _firestore.collection('schools').doc(schoolId).get();
      if (doc.exists) {
        return SchoolModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get school: $e');
    }
  }

  // Get school by code
  Future<SchoolModel?> getSchoolByCode(String schoolCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('schools')
          .where('schoolCode', isEqualTo: schoolCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SchoolModel.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get school by code: $e');
    }
  }

  // Update school
  Future<void> updateSchool(String schoolId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('schools').doc(schoolId).update(updates);
    } catch (e) {
      throw Exception('Failed to update school: $e');
    }
  }

  // Update subscription status
  Future<void> updateSubscriptionStatus(
    String schoolId,
    SubscriptionStatus status, {
    DateTime? subscriptionEndDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'subscriptionStatus': _subscriptionStatusToString(status),
        'updatedAt': Timestamp.now(),
      };

      if (subscriptionEndDate != null) {
        updates['subscriptionEndDate'] = Timestamp.fromDate(subscriptionEndDate);
      }

      await _firestore.collection('schools').doc(schoolId).update(updates);
    } catch (e) {
      throw Exception('Failed to update subscription: $e');
    }
  }

  // Increment student count
  Future<void> incrementStudentCount(String schoolId) async {
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'currentStudents': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment student count: $e');
    }
  }

  // Decrement student count
  Future<void> decrementStudentCount(String schoolId) async {
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'currentStudents': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to decrement student count: $e');
    }
  }

  // Increment teacher count
  Future<void> incrementTeacherCount(String schoolId) async {
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'currentTeachers': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment teacher count: $e');
    }
  }

  // Decrement teacher count
  Future<void> decrementTeacherCount(String schoolId) async {
    try {
      await _firestore.collection('schools').doc(schoolId).update({
        'currentTeachers': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to decrement teacher count: $e');
    }
  }

  // Check if school subscription is active
  Future<bool> isSchoolActive(String schoolId) async {
    try {
      final school = await getSchoolById(schoolId);
      if (school == null) return false;
      return school.isSubscriptionActive && !school.isSubscriptionExpired;
    } catch (e) {
      return false;
    }
  }

  // Stream school data
  Stream<SchoolModel?> streamSchool(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .snapshots()
        .map((doc) => doc.exists ? SchoolModel.fromDocument(doc) : null);
  }

  // Generate unique school code
  Future<String> _generateSchoolCode() async {
    String code = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (exists && attempts < maxAttempts) {
      // Generate code: SCH + 4 random digits
      final random = DateTime.now().millisecondsSinceEpoch % 10000;
      code = 'SCH${random.toString().padLeft(4, '0')}';

      // Check if code exists
      final querySnapshot = await _firestore
          .collection('schools')
          .where('schoolCode', isEqualTo: code)
          .limit(1)
          .get();

      exists = querySnapshot.docs.isNotEmpty;
      attempts++;
    }

    if (exists || code.isEmpty) {
      throw Exception('Failed to generate unique school code');
    }

    return code;
  }

  // Validate school code format
  static bool isValidSchoolCode(String code) {
    final regex = RegExp(r'^SCH\d{4}$');
    return regex.hasMatch(code.toUpperCase());
  }

  // Helper to convert SubscriptionStatus to string
  String _subscriptionStatusToString(SubscriptionStatus status) {
    switch (status) {
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
}
