import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload a file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String path, // e.g., 'profile_pictures', 'homework', 'notes', 'videos', 'thumbnails'
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate file name if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFileName = file.path.split('/').last;
      final fileExtension = originalFileName.split('.').last;
      final finalFileName = fileName ?? '${timestamp}_$originalFileName';

      // Create storage path
      final storagePath = '$path/${user.uid}/$finalFileName';

      final ref = _storage.ref().child(storagePath);

      // Upload file with metadata
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'originalName': originalFileName,
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
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

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload multiple files
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String path,
    Function(int current, int total, double progress)? onProgress,
  }) async {
    try {
      final uploadedUrls = <String>[];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final url = await uploadFile(
          file: file,
          path: path,
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

  // Upload profile picture
  Future<String> uploadProfilePicture(File imageFile, {Function(double)? onProgress}) async {
    return await uploadFile(
      file: imageFile,
      path: 'profile_pictures',
      fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: onProgress,
    );
  }

  // Upload homework attachment
  Future<String> uploadHomeworkAttachment(File file, {Function(double)? onProgress}) async {
    return await uploadFile(
      file: file,
      path: 'homework_attachments',
      onProgress: onProgress,
    );
  }

  // Upload homework submission attachment
  Future<String> uploadHomeworkSubmissionAttachment(File file, {Function(double)? onProgress}) async {
    return await uploadFile(
      file: file,
      path: 'homework_submissions',
      onProgress: onProgress,
    );
  }

  // Upload video file
  Future<String> uploadVideoFile(File videoFile, {Function(double)? onProgress}) async {
    return await uploadFile(
      file: videoFile,
      path: 'videos',
      onProgress: onProgress,
    );
  }

  // Upload video thumbnail
  Future<String> uploadVideoThumbnail(File imageFile, {Function(double)? onProgress}) async {
    return await uploadFile(
      file: imageFile,
      path: 'video_thumbnails',
      fileName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: onProgress,
    );
  }

  // Upload note attachment (already handled by NotesService, but keeping for consistency)
  Future<String> uploadNoteAttachment(File file, {Function(double)? onProgress}) async {
    return await uploadFile(
      file: file,
      path: 'notes',
      onProgress: onProgress,
    );
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get content type from file extension
  String? _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }
}
