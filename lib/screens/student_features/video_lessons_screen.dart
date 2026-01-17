import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/video_lesson_model.dart';
import '../../models/student_model.dart';
import '../../services/video_service.dart';

class VideoLessonsScreen extends StatefulWidget {
  const VideoLessonsScreen({super.key});

  @override
  State<VideoLessonsScreen> createState() => _VideoLessonsScreenState();
}

class _VideoLessonsScreenState extends State<VideoLessonsScreen> {
  final VideoService _videoService = VideoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentModel? _student;
  String? _selectedSubject;
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    }
  }

  Future<void> _playVideo(VideoLessonModel video) async {
    // Increment view count
    _videoService.incrementViews(video.videoId);

    // Open video URL
    final uri = Uri.parse(video.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open video URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Video Lessons", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<VideoLessonModel>>(
        stream: _student?.classId != null 
            ? _videoService.getStudentVideos(_student!.classId)
            : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading videos: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No video lessons available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Videos will appear here once teachers upload them',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Get unique subjects
          final subjects = videos.map((v) => v.subject).toSet().toList()..sort();
          if (_subjects.isEmpty) {
            _subjects = subjects;
          }

          final filteredVideos = _selectedSubject == null
              ? videos
              : videos.where((v) => v.subject == _selectedSubject).toList();

          return Column(
            children: [
              // Subject Filter
              if (subjects.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSubjectChip(null, 'All'),
                      ...subjects.map((subject) => _buildSubjectChip(subject, subject)),
                    ],
                  ),
                ),
              // Video List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ...filteredVideos.map((video) => _buildVideoCard(video)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubjectChip(String? subject, String label) {
    final isSelected = _selectedSubject == subject;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSubject = selected ? subject : null;
          });
        },
      ),
    );
  }

  Widget _buildVideoCard(VideoLessonModel video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          GestureDetector(
            onTap: () => _playVideo(video),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: video.thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(video.thumbnailUrl!),
                        fit: BoxFit.cover,
                        opacity: 0.8,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (video.thumbnailUrl == null)
                    Center(
                      child: Icon(
                        Icons.video_library,
                        size: 60,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Video Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  video.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        video.subject,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (video.chapter != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          video.chapter!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      video.teacherName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${video.views} views',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}