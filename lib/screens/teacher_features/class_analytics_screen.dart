import 'package:flutter/material.dart';

class ClassAnalyticsScreen extends StatelessWidget {
  const ClassAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text("Class Performance", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Overall Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildBarChart("Mon", 0.9),
            _buildBarChart("Tue", 0.85),
            _buildBarChart("Wed", 0.95),
            _buildBarChart("Thu", 0.70),
            _buildBarChart("Fri", 0.88),
            
            const SizedBox(height: 30),
            const Text("Subject Averages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildProgressCard("Mathematics", 0.85, Colors.orange),
            _buildProgressCard("Science", 0.78, Colors.blue),
            _buildProgressCard("English", 0.92, Colors.green),
            _buildProgressCard("History", 0.65, Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String day, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(
            child: Stack(
              children: [
                Container(height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 12, decoration: BoxDecoration(color: const Color(0xFF00897B), borderRadius: BorderRadius.circular(6))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text("${(pct * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String subject, double val, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)), Text("${(val * 100).toInt()}%")]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: val, backgroundColor: color.withOpacity(0.1), color: color, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}