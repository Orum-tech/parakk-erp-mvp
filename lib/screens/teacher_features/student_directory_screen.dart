import 'package:flutter/material.dart';

class StudentDirectoryScreen extends StatelessWidget {
  const StudentDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> students = [
      {"name": "Aryan Sharma", "roll": "24", "bg": Colors.blue},
      {"name": "Rohan Das", "roll": "25", "bg": Colors.green},
      {"name": "Sneha Gupta", "roll": "26", "bg": Colors.orange},
      {"name": "Vikram Singh", "roll": "27", "bg": Colors.purple},
      {"name": "Anjali Mehta", "roll": "28", "bg": Colors.redAccent},
      {"name": "Kabir Khan", "roll": "29", "bg": Colors.teal},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Student Directory", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.search))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: s['bg'].withOpacity(0.1),
                child: Text(s['name'][0], style: TextStyle(color: s['bg'], fontWeight: FontWeight.bold)),
              ),
              title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Roll No: ${s['roll']} • Class 10-A"),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Calling ${s['name']}'s Guardian...")));
                },
              ),
              onTap: () {
                // Future: Open Student Profile
              },
            ),
          );
        },
      ),
    );
  }
}