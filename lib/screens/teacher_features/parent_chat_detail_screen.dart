import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class ParentChatDetailScreen extends StatefulWidget {
  final String parentId;
  final String parentName;
  final String? parentEmail;
  final String studentName;
  final String? studentId;

  const ParentChatDetailScreen({
    super.key,
    required this.parentId,
    required this.parentName,
    this.parentEmail,
    required this.studentName,
    this.studentId,
  });

  @override
  State<ParentChatDetailScreen> createState() => _ParentChatDetailScreenState();
}

class _ParentChatDetailScreenState extends State<ParentChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _chatId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get or create chat ID
      _chatId = await _chatService.getOrCreateChatId(user.uid, widget.parentId);

      // Mark messages as read
      await _chatService.markMessagesAsRead(_chatId!, widget.parentId);

      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(
        chatId: _chatId!,
        receiverId: widget.parentId,
        receiverName: widget.parentName,
        message: message,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Restore message on error
      _messageController.text = message;
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.parentName, style: const TextStyle(color: Colors.black, fontSize: 16)),
              Text("Parent of ${widget.studentName}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.parentName, style: const TextStyle(color: Colors.black, fontSize: 16)),
            Text("Parent of ${widget.studentName}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          if (widget.parentEmail != null)
            IconButton(
              icon: const Icon(Icons.email),
              onPressed: () async {
                final email = widget.parentEmail!;
                final uri = Uri.parse('mailto:$email');
                // Use url_launcher if available
                // await launchUrl(uri);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null
                ? const Center(child: Text('Error loading chat'))
                : StreamBuilder<List<ChatMessageModel>>(
                    stream: _chatService.getChatMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation with ${widget.parentName}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == _auth.currentUser?.uid;
                          final showDate = index == 0 ||
                              _shouldShowDate(messages[index - 1].createdAt, message.createdAt);

                          return Column(
                            children: [
                              if (showDate) _buildDateSeparator(message.createdAt.toDate()),
                              _buildMessageBubble(message, isMe),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFF00897B),
                  radius: 24,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    final timeFormat = DateFormat('hh:mm a');
    final timeStr = timeFormat.format(message.createdAt.toDate());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00897B) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (isMe && message.isRead) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 14, color: Colors.blue[300]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    String dateStr;
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      dateStr = 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      dateStr = 'Yesterday';
    } else {
      dateStr = dateFormat.format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateStr,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400])),
        ],
      ),
    );
  }

  bool _shouldShowDate(Timestamp previous, Timestamp current) {
    final prevDate = previous.toDate();
    final currDate = current.toDate();
    return prevDate.year != currDate.year ||
        prevDate.month != currDate.month ||
        prevDate.day != currDate.day;
  }
}
