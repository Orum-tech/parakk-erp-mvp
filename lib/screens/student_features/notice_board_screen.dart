import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notice_service.dart';
import '../../models/notice_model.dart';
import '../../models/student_model.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final NoticeService _noticeService = NoticeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StudentModel? _student;
  String? _classId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        final student = StudentModel.fromDocument(studentDoc);
        setState(() {
          _student = student;
          _classId = student.classId;
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Announcements", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<NoticeModel>>(
              stream: _noticeService.getStudentNotices(_classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadStudentData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final notices = snapshot.data ?? [];

                if (notices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No notices available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return _buildNoticeCard(notice);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    Color typeColor;
    switch (notice.noticeType) {
      case NoticeType.urgent:
        typeColor = Colors.red;
        break;
      case NoticeType.academic:
        typeColor = Colors.purple;
        break;
      case NoticeType.event:
        typeColor = Colors.blue;
        break;
      case NoticeType.holiday:
        typeColor = Colors.orange;
        break;
      case NoticeType.admin:
        typeColor = Colors.orange;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: notice.noticeType == NoticeType.urgent
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    notice.noticeTypeString,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatDate(notice.createdAt.toDate()),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  notice.description,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
                if (notice.createdByName != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        notice.createdByName!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (notice.expiryDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.orange[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: ${_formatDate(notice.expiryDate!)}',
                        style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    }
  }
}