import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/chat_service.dart';
import 'parent_chat_detail_screen.dart';

class ParentChatScreen extends StatefulWidget {
  const ParentChatScreen({super.key});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _classId;
  List<Map<String, dynamic>> _parentChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParentChats();
  }

  Future<void> _loadParentChats() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get teacher's class
      _classId = await _attendanceService.getClassTeacherClassId();
      if (_classId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get all students in the class
      final students = await _attendanceService.getStudentsByClass(_classId!);

      // Get parent information for each student
      final parentChatsMap = <String, Map<String, dynamic>>{};

      for (var student in students) {
        if (student.parentId != null && student.parentId!.isNotEmpty) {
          // Check if we already have this parent
          if (!parentChatsMap.containsKey(student.parentId)) {
            // Get parent details
            final parentDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(student.parentId)
                .get();

            if (parentDoc.exists) {
              final parentData = parentDoc.data()!;
              final parentName = parentData['name'] ?? 'Unknown Parent';
              final parentEmail = parentData['email'];

              // Get chat info
              final chatId = await _chatService.getOrCreateChatId(user.uid, student.parentId!);
              final unreadCount = await _chatService.getUnreadCount(chatId);

              // Get last message
              final messages = await _chatService.getChatMessages(chatId).first;
              String lastMessage = 'No messages yet';
              DateTime? lastMessageTime;

              if (messages.isNotEmpty) {
                final lastMsg = messages.last;
                lastMessage = lastMsg.message;
                lastMessageTime = lastMsg.createdAt.toDate();
              }

              parentChatsMap[student.parentId!] = {
                'parentId': student.parentId,
                'parentName': parentName,
                'parentEmail': parentEmail,
                'studentId': student.uid,
                'studentName': student.name,
                'studentClass': student.className ?? 'N/A',
                'chatId': chatId,
                'lastMessage': lastMessage,
                'lastMessageTime': lastMessageTime,
                'unreadCount': unreadCount,
              };
            }
          } else {
            // Add additional student to existing parent entry
            final existing = parentChatsMap[student.parentId!]!;
            final currentStudents = existing['students'] as List<Map<String, dynamic>>? ?? [];
            currentStudents.add({
              'studentId': student.uid,
              'studentName': student.name,
            });
            existing['students'] = currentStudents;
          }
        }
      }

      setState(() {
        _parentChats = parentChatsMap.values.toList();
        // Sort by last message time (most recent first)
        _parentChats.sort((a, b) {
          final timeA = a['lastMessageTime'] as DateTime?;
          final timeB = b['lastMessageTime'] as DateTime?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading parent chats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Parent Messages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParentChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parentChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No parent chats',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Parents of students in your class will appear here',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadParentChats,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _parentChats.length,
                    itemBuilder: (context, index) {
                      final chat = _parentChats[index];
                      return _buildChatTile(context, chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    final parentName = chat['parentName'] as String;
    final studentName = chat['studentName'] as String;
    final studentClass = chat['studentClass'] as String;
    final lastMessage = chat['lastMessage'] as String;
    final lastMessageTime = chat['lastMessageTime'] as DateTime?;
    final unreadCount = chat['unreadCount'] as int;

    String timeStr = 'No messages';
    if (lastMessageTime != null) {
      final now = DateTime.now();
      final difference = now.difference(lastMessageTime);

      if (difference.inDays == 0) {
        timeStr = DateFormat('hh:mm a').format(lastMessageTime);
      } else if (difference.inDays == 1) {
        timeStr = 'Yesterday';
      } else if (difference.inDays < 7) {
        timeStr = DateFormat('EEE').format(lastMessageTime);
      } else {
        timeStr = DateFormat('MMM dd').format(lastMessageTime);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF00897B).withOpacity(0.1),
          child: Text(
            parentName.isNotEmpty ? parentName[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: Color(0xFF00897B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          parentName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            Text(
              "[$studentName - $studentClass] ",
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.green : Colors.grey,
                fontSize: 12,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => ParentChatDetailScreen(
                parentId: chat['parentId'] as String,
                parentName: parentName,
                parentEmail: chat['parentEmail'] as String?,
                studentName: studentName,
                studentId: chat['studentId'] as String?,
              ),
            ),
          ).then((_) => _loadParentChats()); // Refresh on return
        },
      ),
    );
  }
}
