import 'package:flutter/material.dart';

class BehaviourLogScreen extends StatefulWidget {
  const BehaviourLogScreen({super.key});

  @override
  State<BehaviourLogScreen> createState() => _BehaviourLogScreenState();
}

class _BehaviourLogScreenState extends State<BehaviourLogScreen> {
  final List<String> _students = ["Aryan Sharma", "Rohan Das", "Sneha Gupta", "Vikram Singh", "Anjali Mehta", "Kabir Khan"];

  void _addLog(String student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Add Remark for $student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeedbackOption("Positive", Icons.thumb_up, Colors.green),
                _buildFeedbackOption("Negative", Icons.thumb_down, Colors.red),
                _buildFeedbackOption("Neutral", Icons.chat_bubble, Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                hintText: "Enter specific comment...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feedback Saved!")));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                child: const Text("SAVE LOG"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackOption(String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text("Behaviour Monitor", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.teal[50], child: Text("${index + 1}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
              title: Text(_students[index], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: () => _addLog(_students[index]),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: const StadiumBorder()),
                child: const Text("Log"),
              ),
            ),
          );
        },
      ),
    );
  }
}