import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/incident_log_model.dart';

class IncidentLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create incident log
  Future<String> createIncidentLog({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required String issue,
    required String description,
    required IncidentSeverity severity,
    required DateTime incidentDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacherData = teacherDoc.data()!;
      final teacherName = teacherData['name'] ?? 'Unknown Teacher';

      String severityString;
      switch (severity) {
        case IncidentSeverity.minor:
          severityString = 'Minor';
          break;
        case IncidentSeverity.moderate:
          severityString = 'Moderate';
          break;
        case IncidentSeverity.severe:
          severityString = 'Severe';
          break;
      }

      final incidentData = {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'className': className,
        'issue': issue,
        'description': description,
        'severity': severityString,
        'status': 'Pending',
        'reportedBy': user.uid,
        'reportedByName': teacherName,
        'incidentDate': Timestamp.fromDate(incidentDate),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      final docRef = await _firestore.collection('incident_logs').add(incidentData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create incident log: $e');
    }
  }

  // Get incident logs for a class
  Stream<List<IncidentLogModel>> getClassIncidentLogs(String? classId) {
    try {
      if (classId == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('incident_logs')
          .where('classId', isEqualTo: classId)
          .orderBy('incidentDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => IncidentLogModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch incident logs: $e');
    }
  }

  // Update incident status
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus status,
    String? actionTaken,
  }) async {
    try {
      String statusString;
      switch (status) {
        case IncidentStatus.pending:
          statusString = 'Pending';
          break;
        case IncidentStatus.underReview:
          statusString = 'Under Review';
          break;
        case IncidentStatus.actionTaken:
          statusString = 'Action Taken';
          break;
        case IncidentStatus.resolved:
          statusString = 'Resolved';
          break;
      }

      final updateData = {
        'status': statusString,
        'updatedAt': Timestamp.now(),
      };

      if (actionTaken != null) {
        updateData['actionTaken'] = actionTaken;
      }

      if (status == IncidentStatus.resolved) {
        updateData['resolvedDate'] = Timestamp.now();
      }

      await _firestore.collection('incident_logs').doc(incidentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update incident status: $e');
    }
  }

  // Delete incident log
  Future<void> deleteIncidentLog(String incidentId) async {
    try {
      await _firestore.collection('incident_logs').doc(incidentId).delete();
    } catch (e) {
      throw Exception('Failed to delete incident log: $e');
    }
  }
}
