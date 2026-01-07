import 'package:flutter/material.dart';

class LessonPlanScreen extends StatelessWidget {
  const LessonPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text("Lesson Plan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("This Week's Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildPlanCard("Monday", "Mathematics", "Quadratic Equations - Intro", true),
          _buildPlanCard("Tuesday", "Mathematics", "Solving by Factorization", true),
          _buildPlanCard("Wednesday", "Mathematics", "Completing the Square", false),
          _buildPlanCard("Thursday", "Mathematics", "Quadratic Formula", false),
          _buildPlanCard("Friday", "Mathematics", "Weekly Test", false),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String day, String subject, String topic, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDone ? Colors.green[50] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDone ? Colors.green : Colors.transparent)),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
              Text(topic, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isDone ? TextDecoration.lineThrough : null)),
              Text(subject, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}