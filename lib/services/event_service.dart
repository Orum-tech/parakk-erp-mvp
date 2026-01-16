import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create event (Teacher)
  Future<String> createEvent({
    required String title,
    String? description,
    required EventCategory category,
    String? location,
    required DateTime eventDate,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? targetAudience, // classIds or ['all'] for all students
    List<String>? attachmentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get teacher info from Firestore
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');

      final teacherData = teacherDoc.data()!;

      final event = EventModel(
        eventId: '', // Will be set by Firestore
        title: title,
        description: description,
        category: category,
        location: location,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        organizerId: user.uid,
        organizerName: teacherData['name'] ?? '',
        targetAudience: targetAudience ?? ['all'],
        attachmentUrls: attachmentUrls,
        isActive: true,
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore.collection('events').add(event.toMap());
      
      // Update with generated ID
      await docRef.update({'eventId': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Get all events (for teachers - all events)
  Stream<List<EventModel>> getAllEvents() {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Get events for student (filtered by targetAudience)
  Stream<List<EventModel>> getStudentEvents(String studentClassId) {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        final allEvents = snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList();
        
        // Filter events that are either:
        // 1. Targeted to 'all'
        // 2. Targeted to the student's class
        return allEvents.where((event) {
          if (event.targetAudience == null || event.targetAudience!.isEmpty) return false;
          return event.targetAudience!.contains('all') || event.targetAudience!.contains(studentClassId);
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Get events created by a teacher
  Stream<List<EventModel>> getTeacherEvents() {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.value([]);

      return _firestore
          .collection('events')
          .where('organizerId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Update event
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    EventCategory? category,
    String? location,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? targetAudience,
    List<String>? attachmentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is the organizer
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      
      final eventData = eventDoc.data()!;
      if (eventData['organizerId'] != user.uid) {
        throw Exception('You do not have permission to update this event');
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = _categoryToString(category);
      if (location != null) updateData['location'] = location;
      if (eventDate != null) updateData['eventDate'] = Timestamp.fromDate(eventDate);
      if (startTime != null) updateData['startTime'] = Timestamp.fromDate(startTime);
      if (endTime != null) updateData['endTime'] = Timestamp.fromDate(endTime);
      if (targetAudience != null) updateData['targetAudience'] = targetAudience;
      if (attachmentUrls != null) updateData['attachmentUrls'] = attachmentUrls;

      await _firestore.collection('events').doc(eventId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event (soft delete by setting isActive to false)
  Future<void> deleteEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is the organizer
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      
      final eventData = eventDoc.data()!;
      if (eventData['organizerId'] != user.uid) {
        throw Exception('You do not have permission to delete this event');
      }

      await _firestore.collection('events').doc(eventId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Get all classes for target audience selection
  Future<List<Map<String, String>>> getAllClasses() async {
    try {
      final classesSnapshot = await _firestore.collection('classes').get();
      return classesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': '${data['name'] ?? ''}${data['section'] != null ? '-${data['section']}' : ''}',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _categoryToString(EventCategory category) {
    switch (category) {
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.meeting:
        return 'Meeting';
      case EventCategory.holiday:
        return 'Holiday';
      case EventCategory.other:
        return 'Other';
    }
  }
}
