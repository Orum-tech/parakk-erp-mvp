import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? teacherEmail;
  final String? subject;

  const ChatDetailScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.teacherEmail,
    this.subject,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
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
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get or create chat ID
      _chatId = await _chatService.getOrCreateChatId(user.uid, widget.teacherId);
      
      // Mark messages as read
      await _chatService.markMessagesAsRead(_chatId!, widget.teacherId);

      setState(() => _isLoading = false);

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing chat: $e'), backgroundColor: Colors.red),
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
        receiverId: widget.teacherId,
        receiverName: widget.teacherName,
        message: message,
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e'), backgroundColor: Colors.red),
        );
      }
      // Restore message if send failed
      _messageController.text = message;
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _chatId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.teacherName),
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
            Text(
              widget.teacherName,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.subject != null)
              Text(
                widget.subject!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.getChatMessages(_chatId!),
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
                          'Error loading messages: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                          'Start a conversation with ${widget.teacherName}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser?.uid;
                    final showDate = index == 0 || 
                        (index > 0 && _shouldShowDate(messages[index - 1].createdAt.toDate(), message.createdAt.toDate()));

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

          // Input Field
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    backgroundColor: const Color(0xFF1565C0),
                    radius: 24,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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
          color: isMe ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
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
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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

  bool _shouldShowDate(DateTime prevDate, DateTime currentDate) {
    return prevDate.year != currentDate.year ||
        prevDate.month != currentDate.month ||
        prevDate.day != currentDate.day;
  }
}
