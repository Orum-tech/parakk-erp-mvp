import 'package:flutter/material.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  // Mock Homework List
  final List<Map<String, dynamic>> _homeworkList = [
    {
      "title": "Algebra Exercise 5.1",
      "class": "Class 10-A",
      "dueDate": "Tomorrow",
      "subject": "Maths",
      "submitted": 15,
      "total": 40
    },
    {
      "title": "Essay on Pollution",
      "class": "Class 9-B",
      "dueDate": "Jan 15",
      "subject": "English",
      "submitted": 32,
      "total": 38
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Homework & Assignments", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Future: Open Add Homework Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add Homework Feature Coming Soon"))
          );
        },
        label: const Text("Create New"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      body: _homeworkList.isEmpty 
          ? const Center(child: Text("No homework assigned yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _homeworkList.length,
              itemBuilder: (context, index) {
                final hw = _homeworkList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hw['subject'],
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Text(
                              "Due: ${hw['dueDate']}",
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hw['title'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          hw['class'],
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 15),
                        // Submission Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Submissions", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text("${hw['submitted']}/${hw['total']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                              value: hw['submitted'] / hw['total'],
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.green,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}