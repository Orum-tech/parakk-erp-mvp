import 'package:flutter/material.dart';

class TeacherChatScreen extends StatelessWidget {
  const TeacherChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock List of Teachers
    final List<Map<String, String>> teachers = [
      {"name": "Rahul Sir", "subject": "Mathematics", "status": "Online"},
      {"name": "Priya Mam", "subject": "English", "status": "Offline"},
      {"name": "Amit Sir", "subject": "Science", "status": "Busy"},
      {"name": "Suresh Sir", "subject": "History", "status": "Online"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Ask Teachers", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: teachers.length,
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      teacher["name"]![0], 
                      style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: teacher["status"] == "Online" ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )
                ],
              ),
              title: Text(teacher["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(teacher["subject"]!),
              trailing: ElevatedButton(
                onPressed: () {
                  // Chat open karne ka logic yahan aayega
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Chatting with ${teacher['name']}..."))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("Chat", style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}