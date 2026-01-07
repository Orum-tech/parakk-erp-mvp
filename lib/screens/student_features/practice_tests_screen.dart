import 'package:flutter/material.dart';

class PracticeTestsScreen extends StatelessWidget {
  const PracticeTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Practice Tests", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildQuizCard("Maths Weekly Quiz", "Algebra & Geometry", "30 Mins", "20 Questions", Colors.orange),
          _buildQuizCard("Physics Mock Test", "Laws of Motion", "45 Mins", "25 Questions", Colors.blue),
          _buildQuizCard("English Grammar", "Tenses & Verbs", "20 Mins", "15 Questions", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildQuizCard(String title, String topic, String time, String qs, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(topic, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 20),
              Icon(Icons.format_list_numbered, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(qs, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Start Quiz"),
            ),
          )
        ],
      ),
    );
  }
}