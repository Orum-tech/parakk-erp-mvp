import 'package:flutter/material.dart';

class MarksEntryScreen extends StatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final List<String> students = ["Aryan Sharma", "Rohan Das", "Sneha Gupta", "Vikram Singh", "Anjali Mehta"];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Enter Marks", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mid-Term Exam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Mathematics", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Text("Max: 100", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(15),
              itemCount: students.length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Text("${index + 1}.", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 15),
                      Expanded(child: Text(students[index], style: const TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: "00",
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marks Saved Successfully! 💾"), backgroundColor: Colors.green));
        },
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text("Save All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}