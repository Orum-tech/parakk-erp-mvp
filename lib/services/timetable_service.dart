import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/timetable_model.dart';
import '../models/teacher_model.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if teacher is class teacher for a class
  Future<bool> isClassTeacherForClass(String classId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) return false;

      final teacher = TeacherModel.fromDocument(teacherDoc);
      return teacher.classTeacherClassId == classId;
    } catch (e) {
      return false;
    }
  }

  // Get class teacher's class
  Future<String?> getClassTeacherClassId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) return null;

      final teacher = TeacherModel.fromDocument(teacherDoc);
      return teacher.classTeacherClassId;
    } catch (e) {
      return null;
    }
  }

  // Create or update timetable entry (Class Teacher only)
  Future<String> createOrUpdateTimetableEntry({
    String? timetableId,
    required String classId,
    required String className,
    required DayOfWeek day,
    required int periodNumber,
    required String subjectId,
    required String subjectName,
    required String teacherId,
    required String teacherName,
    required DateTime startTime,
    required DateTime endTime,
    String? room,
    bool isBreak = false,
    String? breakType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify teacher is class teacher for this class
      if (!await isClassTeacherForClass(classId)) {
        throw Exception('Only class teacher can create/edit timetable for this class');
      }

      final timetable = TimetableModel(
        timetableId: timetableId ?? '',
        classId: classId,
        className: className,
        day: day,
        periodNumber: periodNumber,
        subjectId: subjectId,
        subjectName: subjectName,
        teacherId: teacherId,
        teacherName: teacherName,
        startTime: startTime,
        endTime: endTime,
        room: room,
        isBreak: isBreak,
        breakType: breakType,
        createdAt: Timestamp.now(),
      );

      if (timetableId != null && timetableId.isNotEmpty) {
        // Update existing
        await _firestore.collection('timetable').doc(timetableId).update(timetable.toMap());
        return timetableId;
      } else {
        // Create new
        final docRef = await _firestore.collection('timetable').add(timetable.toMap());
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to save timetable: $e');
    }
  }

  // Delete timetable entry (Class Teacher only)
  Future<void> deleteTimetableEntry(String timetableId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timetableDoc = await _firestore.collection('timetable').doc(timetableId).get();
      if (!timetableDoc.exists) throw Exception('Timetable entry not found');

      final timetable = TimetableModel.fromDocument(timetableDoc);

      // Verify teacher is class teacher for this class
      if (!await isClassTeacherForClass(timetable.classId)) {
        throw Exception('Only class teacher can delete timetable for this class');
      }

      await _firestore.collection('timetable').doc(timetableId).delete();
    } catch (e) {
      throw Exception('Failed to delete timetable: $e');
    }
  }

  // Get timetable for a class
  Stream<List<TimetableModel>> getClassTimetable(String classId) {
    try {
      return _firestore
          .collection('timetable')
          .where('classId', isEqualTo: classId)
          .orderBy('day')
          .orderBy('periodNumber')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TimetableModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch timetable: $e');
    }
  }

  // Get timetable for a specific day and class
  Future<List<TimetableModel>> getTimetableByDayAndClass({
    required String classId,
    required DayOfWeek day,
  }) async {
    try {
      // Convert DayOfWeek to string
      String dayString;
      switch (day) {
        case DayOfWeek.monday:
          dayString = 'Monday';
          break;
        case DayOfWeek.tuesday:
          dayString = 'Tuesday';
          break;
        case DayOfWeek.wednesday:
          dayString = 'Wednesday';
          break;
        case DayOfWeek.thursday:
          dayString = 'Thursday';
          break;
        case DayOfWeek.friday:
          dayString = 'Friday';
          break;
        case DayOfWeek.saturday:
          dayString = 'Saturday';
          break;
        case DayOfWeek.sunday:
          dayString = 'Sunday';
          break;
      }

      final snapshot = await _firestore
          .collection('timetable')
          .where('classId', isEqualTo: classId)
          .where('day', isEqualTo: dayString)
          .orderBy('periodNumber')
          .get();

      return snapshot.docs
          .map((doc) => TimetableModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch timetable: $e');
    }
  }

  // Get teacher's timetable (all classes they teach)
  Stream<List<TimetableModel>> getTeacherTimetable(String teacherId) {
    try {
      return _firestore
          .collection('timetable')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('day')
          .orderBy('periodNumber')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TimetableModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch teacher timetable: $e');
    }
  }

  // Get student's timetable (based on their class)
  Stream<List<TimetableModel>> getStudentTimetable(String classId) {
    return getClassTimetable(classId);
  }

  // Batch create/update timetable entries (Class Teacher only)
  Future<void> batchUpdateTimetable({
    required String classId,
    required String className,
    required List<TimetableModel> entries,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify teacher is class teacher for this class
      if (!await isClassTeacherForClass(classId)) {
        throw Exception('Only class teacher can update timetable for this class');
      }

      // Delete existing entries for this class
      final existingSnapshot = await _firestore
          .collection('timetable')
          .where('classId', isEqualTo: classId)
          .get();

      final batch = _firestore.batch();
      for (var doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new entries
      for (var entry in entries) {
        final docRef = _firestore.collection('timetable').doc();
        batch.set(docRef, entry.copyWith(timetableId: docRef.id).toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update timetable: $e');
    }
  }
}
