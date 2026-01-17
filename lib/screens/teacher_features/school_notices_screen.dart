import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/notice_model.dart';
import '../../services/notice_service.dart';
import '../../models/teacher_model.dart';

class SchoolNoticesScreen extends StatefulWidget {
  const SchoolNoticesScreen({super.key});

  @override
  State<SchoolNoticesScreen> createState() => _SchoolNoticesScreenState();
}

class _SchoolNoticesScreenState extends State<SchoolNoticesScreen> {
  final NoticeService _noticeService = NoticeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TeacherModel? _teacher;
  String? _classId;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        setState(() {
          _teacher = TeacherModel.fromDocument(teacherDoc);
          _classId = _teacher?.classTeacherClassId;
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
    }
  }

  // Notice Add Karne Wala Dialog Box
  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    NoticeType selectedType = NoticeType.general;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Notice"),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Notice Title", hintText: "e.g., Exam Schedule"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description", hintText: "Type details here..."),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<NoticeType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: "Notice Type"),
                items: NoticeType.values.map((type) {
                  String label;
                  switch (type) {
                    case NoticeType.urgent: label = 'Urgent'; break;
                    case NoticeType.academic: label = 'Academic'; break;
                    case NoticeType.event: label = 'Event'; break;
                    case NoticeType.holiday: label = 'Holiday'; break;
                    case NoticeType.admin: label = 'Admin'; break;
                    default: label = 'General';
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                try {
                  await _noticeService.createNotice(
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    noticeType: selectedType,
                    targetAudience: _classId ?? 'all',
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notice Published Successfully! 📢"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            child: const Text("Publish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("School Board", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoticeDialog,
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add),
        label: const Text("New Notice"),
      ),
      body: StreamBuilder<List<NoticeModel>>(
        stream: _noticeService.getTeacherNotices(classId: _classId),
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
                    'Error loading notices: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
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
                  Text(
                    'No notices available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a new notice to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Stream will automatically update
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return _buildNoticeCard(notice);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    Color tagColor;
    switch (notice.noticeType) {
      case NoticeType.holiday: tagColor = Colors.blue; break;
      case NoticeType.event: tagColor = Colors.orange; break;
      case NoticeType.urgent: tagColor = Colors.red; break;
      case NoticeType.academic: tagColor = Colors.purple; break;
      case NoticeType.admin: tagColor = Colors.blueGrey; break;
      default: tagColor = Colors.teal;
    }

    final dateFormat = DateFormat('dd MMM yyyy');
    final dateStr = dateFormat.format(notice.createdAt.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(notice.noticeTypeString, style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Text(dateStr, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(notice.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(notice.description, style: TextStyle(color: Colors.grey[600], height: 1.4)),
          if (notice.createdByName != null) ...[
            const SizedBox(height: 8),
            Text(
              'By ${notice.createdByName}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}