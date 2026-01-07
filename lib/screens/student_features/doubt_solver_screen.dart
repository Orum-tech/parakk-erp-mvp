import 'package:flutter/material.dart';

class DoubtSolverScreen extends StatefulWidget {
  const DoubtSolverScreen({super.key});

  @override
  State<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends State<DoubtSolverScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"sender": "ai", "text": "Hello Aryan! I am your AI Master. 🤖\nAsk me anything about your subjects!"}
  ];

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": _controller.text});
    });

    String userQuery = _controller.text.toLowerCase();
    _controller.clear();

    // Mock AI Logic (Bina Backend ke reply)
    Future.delayed(const Duration(seconds: 1), () {
      String reply = "I am not sure about that yet. Try asking about Maths or Science!";
      
      if (userQuery.contains("hi") || userQuery.contains("hello")) {
        reply = "Hey there! Ready to learn something new today? 📚";
      } else if (userQuery.contains("math") || userQuery.contains("algebra")) {
        reply = "Math is fun! For Algebra, remember: (a+b)² = a² + 2ab + b². Need help with a specific sum?";
      } else if (userQuery.contains("physics") || userQuery.contains("newton")) {
        reply = "Physics rules! Newton's Second Law is F = ma. Force equals mass times acceleration. 🍎";
      } else if (userQuery.contains("chemistry") || userQuery.contains("atom")) {
        reply = "Chemistry is all about bonds! 🧪 Did you know water is H₂O?";
      } else if (userQuery.contains("exam") || userQuery.contains("test")) {
        reply = "Don't stress! Just focus on your weak topics and practice daily. You got this! 💪";
      } else if (userQuery.contains("thanks") || userQuery.contains("thank you")) {
        reply = "You're welcome! Happy Learning! 🎓";
      }

      if (mounted) {
        setState(() {
          _messages.add({"sender": "ai", "text": reply});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.smart_toy_rounded, color: Color(0xFF1565C0)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Master", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Always Online", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1565C0) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask a doubt...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF1565C0),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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