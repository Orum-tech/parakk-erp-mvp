import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("My Performance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildChartCard("Attendance Trends", "Last 6 Months", Colors.green, Icons.show_chart_rounded),
            const SizedBox(height: 20),
            _buildChartCard("Academic Growth", "Exam Wise Score", Colors.blue, Icons.bar_chart_rounded),
            const SizedBox(height: 20),
            _buildChartCard("Subject Strength", "Weak vs Strong Areas", Colors.purple, Icons.pie_chart_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Center(
              child: Text("Chart Placeholder", style: TextStyle(color: color.withOpacity(0.5), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}