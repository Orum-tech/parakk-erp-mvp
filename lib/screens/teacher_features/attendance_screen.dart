import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _students = [
    {"id": "1", "name": "Aryan Sharma", "roll": 24, "status": "P"},
    {"id": "2", "name": "Rohan Das", "roll": 25, "status": "P"},
    {"id": "3", "name": "Sneha Gupta", "roll": 26, "status": "A"},
    {"id": "4", "name": "Vikram Singh", "roll": 27, "status": "P"},
    {"id": "5", "name": "Anjali Mehta", "roll": 28, "status": "P"},
    {"id": "6", "name": "Kabir Khan", "roll": 29, "status": "P"},
  ];

  @override
  Widget build(BuildContext context) {
    int presentCount = _students.where((s) => s['status'] == 'P').length;
    int absentCount = _students.length - presentCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mark Attendance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text("Class 10-A • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", 
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge("Present", presentCount.toString(), Colors.green),
                _buildStatBadge("Absent", absentCount.toString(), Colors.red),
                _buildStatBadge("Total", _students.length.toString(), Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                bool isPresent = student['status'] == 'P';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isPresent ? Colors.transparent : Colors.red.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: Text("${student['roll']}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusBtn("P", isPresent, Colors.green, () => setState(() => student['status'] = 'P')),
                        const SizedBox(width: 8),
                        _buildStatusBtn("A", !isPresent, Colors.red, () => setState(() => student['status'] = 'A')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Confirm Submission"),
                content: Text("Present: $presentCount\nAbsent: $absentCount\n\nMark these students?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Edit")),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx); // Close Dialog
                      Navigator.pop(context); // Close Screen
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance Submitted! ✅"), backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    child: const Text("Submit"),
                  )
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Submit Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusBtn(String label, bool isActive, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}