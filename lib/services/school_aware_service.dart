import 'package:cloud_firestore/cloud_firestore.dart';
import 'school_context_service.dart';

/// Base service class for school-aware queries
/// All services should extend this or use SchoolContextService to get schoolId
abstract class SchoolAwareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SchoolContextService _schoolContextService = SchoolContextService();

  /// Get the current school ID
  Future<String?> getSchoolId() async {
    return _schoolContextService.getCurrentSchoolId();
  }

  /// Get classes query filtered by schoolId
  Future<Query> getClassesQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('classes')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get students query filtered by schoolId
  Future<Query> getStudentsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('schoolId', isEqualTo: schoolId)
        .where('isActive', isEqualTo: true);
  }

  /// Get teachers query filtered by schoolId
  Future<Query> getTeachersQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'Teacher')
        .where('schoolId', isEqualTo: schoolId)
        .where('isActive', isEqualTo: true);
  }

  /// Get subjects query filtered by schoolId
  Future<Query> getSubjectsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('subjects')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get homework query filtered by schoolId
  Future<Query> getHomeworkQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('homework')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get attendance query filtered by schoolId
  Future<Query> getAttendanceQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('attendance')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get marks query filtered by schoolId
  Future<Query> getMarksQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('marks')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get notices query filtered by schoolId
  Future<Query> getNoticesQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('notices')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get events query filtered by schoolId
  Future<Query> getEventsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('events')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get exams query filtered by schoolId
  Future<Query> getExamsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('exams')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get fees query filtered by schoolId
  Future<Query> getFeesQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get leave requests query filtered by schoolId
  Future<Query> getLeaveRequestsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('leave_requests')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get incident logs query filtered by schoolId
  Future<Query> getIncidentLogsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('incident_logs')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get behaviour logs query filtered by schoolId
  Future<Query> getBehaviourLogsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('behaviour_logs')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get video lessons query filtered by schoolId
  Future<Query> getVideoLessonsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('video_lessons')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get tests query filtered by schoolId
  Future<Query> getTestsQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('tests')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get notes query filtered by schoolId
  Future<Query> getNotesQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('notes')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Get timetable query filtered by schoolId
  Future<Query> getTimetableQuery() async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    return _firestore
        .collection('timetable')
        .where('schoolId', isEqualTo: schoolId);
  }

  /// Helper method to add schoolId to any document before saving
  Future<Map<String, dynamic>> addSchoolIdToData(Map<String, dynamic> data) async {
    final schoolId = await getSchoolId();
    if (schoolId == null || schoolId.isEmpty) {
      throw Exception('School ID not found. User must be linked to a school.');
    }
    data['schoolId'] = schoolId;
    return data;
  }

  /// Helper method to verify schoolId matches current user's school
  Future<bool> verifySchoolId(String? documentSchoolId) async {
    if (documentSchoolId == null || documentSchoolId.isEmpty) return false;
    final currentSchoolId = await getSchoolId();
    return currentSchoolId == documentSchoolId;
  }
}
