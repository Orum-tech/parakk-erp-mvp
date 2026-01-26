import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired,
}

class SchoolInvitation {
  final String invitationId;
  final String schoolId;
  final String schoolName;
  final String email;
  final UserRole role;
  final InvitationStatus status;
  final String? invitedBy;
  final String? invitedByName;
  final DateTime expiresAt;
  final Timestamp createdAt;
  final Timestamp? acceptedAt;
  final String? acceptedBy;

  SchoolInvitation({
    required this.invitationId,
    required this.schoolId,
    required this.schoolName,
    required this.email,
    required this.role,
    required this.status,
    this.invitedBy,
    this.invitedByName,
    required this.expiresAt,
    required this.createdAt,
    this.acceptedAt,
    this.acceptedBy,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canAccept => status == InvitationStatus.pending && !isExpired;

  factory SchoolInvitation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolInvitation(
      invitationId: doc.id,
      schoolId: data['schoolId'] ?? '',
      schoolName: data['schoolName'] ?? '',
      email: data['email'] ?? '',
      role: _roleFromString(data['role'] ?? 'Student'),
      status: _statusFromString(data['status'] ?? 'pending'),
      invitedBy: data['invitedBy'],
      invitedByName: data['invitedByName'],
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      acceptedAt: data['acceptedAt'] as Timestamp?,
      acceptedBy: data['acceptedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invitationId': invitationId,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'email': email.toLowerCase(),
      'role': _roleString,
      'status': _statusString,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'acceptedBy': acceptedBy,
    };
  }

  String get _roleString {
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

  String get _statusString {
    switch (status) {
      case InvitationStatus.pending:
        return 'pending';
      case InvitationStatus.accepted:
        return 'accepted';
      case InvitationStatus.rejected:
        return 'rejected';
      case InvitationStatus.expired:
        return 'expired';
    }
  }

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

  static InvitationStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }
}

class SchoolInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create invitation
  Future<SchoolInvitation> createInvitation({
    required String schoolId,
    required String schoolName,
    required String email,
    required UserRole role,
    String? invitedBy,
    String? invitedByName,
    Duration validity = const Duration(days: 7),
  }) async {
    try {
      // Check if invitation already exists for this email and school
      final existingInvitation = await getInvitationByEmailAndSchool(email, schoolId);
      if (existingInvitation != null && existingInvitation.canAccept) {
        throw Exception('An active invitation already exists for this email');
      }

      final invitation = SchoolInvitation(
        invitationId: '', // Will be set by Firestore
        schoolId: schoolId,
        schoolName: schoolName,
        email: email.trim().toLowerCase(),
        role: role,
        status: InvitationStatus.pending,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        expiresAt: DateTime.now().add(validity),
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore
          .collection('school_invitations')
          .add(invitation.toMap());

      await docRef.update({'invitationId': docRef.id});

      return invitation.copyWith(invitationId: docRef.id);
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }

  // Get invitation by ID
  Future<SchoolInvitation?> getInvitationById(String invitationId) async {
    try {
      final doc = await _firestore
          .collection('school_invitations')
          .doc(invitationId)
          .get();

      if (doc.exists) {
        return SchoolInvitation.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invitation: $e');
    }
  }

  // Get invitation by email and school
  Future<SchoolInvitation?> getInvitationByEmailAndSchool(
    String email,
    String schoolId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('school_invitations')
          .where('email', isEqualTo: email.toLowerCase())
          .where('schoolId', isEqualTo: schoolId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SchoolInvitation.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invitation: $e');
    }
  }

  // Get pending invitations for email
  Future<List<SchoolInvitation>> getPendingInvitationsForEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('school_invitations')
          .where('email', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SchoolInvitation.fromDocument(doc))
          .where((inv) => !inv.isExpired)
          .toList();
    } catch (e) {
      throw Exception('Failed to get invitations: $e');
    }
  }

  // Get invitations for school
  Future<List<SchoolInvitation>> getInvitationsForSchool(
    String schoolId, {
    InvitationStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('school_invitations')
          .where('schoolId', isEqualTo: schoolId);

      if (status != null) {
        query = query.where('status', isEqualTo: _statusToString(status));
      }

      final querySnapshot = await query.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => SchoolInvitation.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get invitations: $e');
    }
  }

  // Accept invitation
  Future<void> acceptInvitation(String invitationId, String userId) async {
    try {
      final invitation = await getInvitationById(invitationId);
      if (invitation == null) {
        throw Exception('Invitation not found');
      }

      if (!invitation.canAccept) {
        throw Exception('Invitation cannot be accepted');
      }

      await _firestore.collection('school_invitations').doc(invitationId).update({
        'status': 'accepted',
        'acceptedAt': Timestamp.now(),
        'acceptedBy': userId,
      });
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Reject invitation
  Future<void> rejectInvitation(String invitationId) async {
    try {
      await _firestore.collection('school_invitations').doc(invitationId).update({
        'status': 'rejected',
      });
    } catch (e) {
      throw Exception('Failed to reject invitation: $e');
    }
  }

  // Cancel invitation
  Future<void> cancelInvitation(String invitationId) async {
    try {
      await _firestore.collection('school_invitations').doc(invitationId).delete();
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  // Mark expired invitations
  Future<void> markExpiredInvitations() async {
    try {
      final querySnapshot = await _firestore
          .collection('school_invitations')
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();

        if (DateTime.now().isAfter(expiresAt)) {
          batch.update(doc.reference, {'status': 'expired'});
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error marking expired invitations: $e');
    }
  }

  // Stream invitations for school
  Stream<List<SchoolInvitation>> streamInvitationsForSchool(String schoolId) {
    return _firestore
        .collection('school_invitations')
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolInvitation.fromDocument(doc))
            .toList());
  }

  String _statusToString(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return 'pending';
      case InvitationStatus.accepted:
        return 'accepted';
      case InvitationStatus.rejected:
        return 'rejected';
      case InvitationStatus.expired:
        return 'expired';
    }
  }
}

// Extension for copyWith
extension SchoolInvitationExtension on SchoolInvitation {
  SchoolInvitation copyWith({
    String? invitationId,
    String? schoolId,
    String? schoolName,
    String? email,
    UserRole? role,
    InvitationStatus? status,
    String? invitedBy,
    String? invitedByName,
    DateTime? expiresAt,
    Timestamp? createdAt,
    Timestamp? acceptedAt,
    String? acceptedBy,
  }) {
    return SchoolInvitation(
      invitationId: invitationId ?? this.invitationId,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedBy: acceptedBy ?? this.acceptedBy,
    );
  }
}
