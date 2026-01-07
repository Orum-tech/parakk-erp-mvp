import 'package:flutter/material.dart';

// --- MAIN CHAT LIST SCREEN ---
class ParentChatScreen extends StatelessWidget {
  const ParentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Parent Messages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          _buildChatTile(context, "Mr. Sharma", "Aryan (10-A)", "Sir, is tomorrow a holiday?", "10:30 AM", true),
          _buildChatTile(context, "Mrs. Verma", "Rohan (10-A)", "Thanks for the update.", "Yesterday", false),
          _buildChatTile(context, "Mr. Iyer", "Priya (10-A)", "Okay, I will check.", "Yesterday", false),
          _buildChatTile(context, "Mrs. Khan", "Zoya (10-A)", "Regarding the fees...", "12 Dec", false),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, String name, String student, String msg, String time, bool isUnread) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF00897B).withOpacity(0.1),
          child: Text(name[0], style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(
          children: [
            Text("[$student] ", style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500)),
            Expanded(child: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: TextStyle(color: isUnread ? Colors.green : Colors.grey, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
            if (isUnread) ...[
              const SizedBox(height: 5),
              const CircleAvatar(radius: 5, backgroundColor: Colors.green)
            ]
          ],
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => ChatDetailScreen(parentName: name, studentName: student)));
        },
      ),
    );
  }
}

// --- SUB SCREEN: CHAT DETAIL (Working) ---
class ChatDetailScreen extends StatefulWidget {
  final String parentName;
  final String studentName;

  const ChatDetailScreen({super.key, required this.parentName, required this.studentName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  
  // Dummy Chat History
  final List<Map<String, dynamic>> _messages = [
    {"msg": "Hello Sir, I wanted to ask about the unit test syllabus.", "isMe": false},
    {"msg": "Hello Mrs. Verma. It includes Chapter 4 and 5.", "isMe": true},
    {"msg": "Okay, thank you sir!", "isMe": false},
  ];

  void _sendMessage() {
    if (_msgController.text.isEmpty) return;
    setState(() {
      _messages.add({"msg": _msgController.text, "isMe": true});
      _msgController.clear();
    });
    // Simulate scroll to bottom if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp-like bg color
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg['isMe'] ? const Color(0xFF00897B) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: msg['isMe'] ? const Radius.circular(12) : Radius.zero,
                        bottomRight: msg['isMe'] ? Radius.zero : const Radius.circular(12),
                      ),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2)],
                    ),
                    child: Text(
                      msg['msg'],
                      style: TextStyle(color: msg['isMe'] ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Field
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFF00897B),
                  radius: 24,
                  child: IconButton(
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
}