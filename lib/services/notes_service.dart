import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/note_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import 'marks_service.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MarksService _marksService = MarksService();

  // Get Firebase Storage instance
  FirebaseStorage get _storage {
    try {
      // Try to get the default instance
      final instance = FirebaseStorage.instance;
      return instance;
    } catch (e) {
      // If that fails, try to get instance for the default app
      try {
        return FirebaseStorage.instanceFor(app: Firebase.app());
      } catch (e2) {
        // Last resort: create a new instance
        throw Exception('Firebase Storage not initialized. Please ensure Firebase is properly configured.');
      }
    }
  }

  // Get classes where teacher teaches
  Future<List<Map<String, String>>> getTeacherClasses(String teacherId) async {
    return await _marksService.getTeacherClasses(teacherId);
  }

  // Get subjects that teacher teaches
  Future<List<Map<String, String>>> getTeacherSubjects(String teacherId) async {
    return await _marksService.getTeacherSubjects(teacherId);
  }

  // Upload note by teacher
  Future<String> uploadTeacherNote({
    required String title,
    String? description,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    String? chapterName,
    required List<String> attachmentUrls,
    String? fileType,
    int? fileSize,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!teacherDoc.exists) throw Exception('Teacher data not found');
      final teacher = TeacherModel.fromDocument(teacherDoc);

      // Verify teacher teaches this class and subject
      final teachesClass = teacher.classIds?.contains(classId) ?? false;
      final teachesSubject = teacher.subjects?.contains(subjectId) ?? false;

      if (!teachesClass || !teachesSubject) {
        throw Exception('You can only upload notes for classes and subjects you teach');
      }

      final note = NoteModel(
        noteId: '',
        title: title,
        description: description,
        subjectId: subjectId,
        subjectName: subjectName,
        classId: classId,
        className: className,
        teacherId: user.uid,
        teacherName: teacher.name,
        chapterName: chapterName,
        attachmentUrls: attachmentUrls,
        fileType: fileType,
        fileSize: fileSize,
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore.collection('notes').add(note.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload note: $e');
    }
  }

  // Upload note by student
  Future<String> uploadStudentNote({
    required String title,
    String? description,
    required String subjectId,
    required String subjectName,
    String? chapterName,
    required List<String> attachmentUrls,
    String? fileType,
    int? fileSize,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!studentDoc.exists) throw Exception('Student data not found');
      final student = StudentModel.fromDocument(studentDoc);

      // For student notes, we use studentId in teacherId field to indicate it's a student note
      // Or we could add a type field. For now, let's use a convention: if teacherId starts with 'student_', it's a student note
      final note = NoteModel(
        noteId: '',
        title: title,
        description: description,
        subjectId: subjectId,
        subjectName: subjectName,
        classId: student.classId,
        className: student.className,
        teacherId: 'student_${user.uid}', // Mark as student note
        teacherName: student.name,
        chapterName: chapterName,
        attachmentUrls: attachmentUrls,
        fileType: fileType,
        fileSize: fileSize,
        createdAt: Timestamp.now(),
      );

      final docRef = await _firestore.collection('notes').add(note.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload note: $e');
    }
  }

  // Get lecture notes (teacher-uploaded notes) for a student's class
  Stream<List<NoteModel>> getLectureNotesForStudent(String studentId) async* {
    try {
      // Get student's class first
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        yield [];
        return;
      }
      
      final student = StudentModel.fromDocument(studentDoc);
      if (student.classId == null) {
        yield [];
        return;
      }

      // Stream notes for this class (without orderBy to avoid composite index)
      yield* _firestore
          .collection('notes')
          .where('classId', isEqualTo: student.classId)
          .snapshots()
          .map((snapshot) {
        // Filter to exclude student notes and sort
        final notes = snapshot.docs
            .where((doc) {
              final data = doc.data();
              final teacherId = data['teacherId'] as String? ?? '';
              // Include only teacher notes (not starting with 'student_')
              return !teacherId.startsWith('student_');
            })
            .map((doc) => NoteModel.fromDocument(doc))
            .toList();
        
        // Sort by createdAt descending
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return notes;
      });
    } catch (e) {
      yield [];
    }
  }

  // Get student's own notes
  Stream<List<NoteModel>> getStudentNotes(String studentId) {
    try {
      return _firestore
          .collection('notes')
          .where('teacherId', isEqualTo: 'student_$studentId')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NoteModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Get notes by class and subject (for teachers)
  Stream<List<NoteModel>> getNotesByClassAndSubject({
    required String classId,
    required String subjectId,
  }) {
    try {
      return _firestore
          .collection('notes')
          .where('classId', isEqualTo: classId)
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .where((doc) {
              final data = doc.data();
              final teacherId = data['teacherId'] as String? ?? '';
              // Exclude student notes
              return !teacherId.startsWith('student_');
            })
            .map((doc) => NoteModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Delete note
  Future<void> deleteNote(String noteId, bool isStudent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noteDoc = await _firestore.collection('notes').doc(noteId).get();
      if (!noteDoc.exists) throw Exception('Note not found');

      final note = NoteModel.fromDocument(noteDoc);
      
      // Verify ownership
      if (isStudent) {
        if (note.teacherId != 'student_${user.uid}') {
          throw Exception('You can only delete your own notes');
        }
      } else {
        if (note.teacherId != user.uid) {
          throw Exception('You can only delete your own notes');
        }
      }

      await _firestore.collection('notes').doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String userId,
    required String classId,
    required String subjectId,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      if (classId.isEmpty) {
        throw Exception('Class ID cannot be empty');
      }
      if (subjectId.isEmpty) {
        throw Exception('Subject ID cannot be empty');
      }
      
      // Verify file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileName = file.path.split('/').last;
      if (fileName.isEmpty) {
        throw Exception('Invalid file name');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last;
      final storagePath = 'notes/$userId/$classId/$subjectId/${timestamp}_$fileName';

      final storage = _storage;
      final ref = storage.ref().child(storagePath);
      
      // Upload file with progress tracking
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'originalName': fileName,
            'uploadedBy': userId,
          },
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        if (onProgress != null && snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      // Wait for upload to complete and get the snapshot
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      
      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        // Get download URL from the snapshot
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      print('Upload error: $e'); // Debug print
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload multiple files
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String userId,
    required String classId,
    required String subjectId,
    Function(int current, int total, double progress)? onProgress,
  }) async {
    try {
      final uploadedUrls = <String>[];
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final url = await uploadFile(
          file: file,
          userId: userId,
          classId: classId,
          subjectId: subjectId,
          onProgress: (progress) {
            if (onProgress != null) {
              // Calculate overall progress
              final overallProgress = (i + progress) / files.length;
              onProgress(i + 1, files.length, overallProgress);
            }
          },
        );
        uploadedUrls.add(url);
      }
      
      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload files: $e');
    }
  }

  // Get content type from file extension
  String? _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // Get file size in bytes
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail - file might already be deleted
    }
  }

  // Increment download count
  Future<void> incrementDownloadCount(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({
        'downloadCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
