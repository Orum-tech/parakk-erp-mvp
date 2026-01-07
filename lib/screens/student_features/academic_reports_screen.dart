import 'package:flutter/material.dart';

class AcademicReportsScreen extends StatelessWidget {
  const AcademicReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Academic Reports", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildReportCard(context, "Term 1 Report Card", "Issued: 15 Oct 2023", "A Grade", Colors.blue),
          _buildReportCard(context, "Mid-Term Analysis", "Issued: 20 Aug 2023", "B+ Grade", Colors.orange),
          _buildReportCard(context, "Monthly Performance", "September 2023", "Top 10%", Colors.purple),
          _buildReportCard(context, "Attendance Summary", "Academic Year 2023-24", "92%", Colors.green),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String subtitle, String grade, Color color) {
    return GestureDetector(
      onTap: () {
        // Open Mock Report View
        Navigator.push(context, MaterialPageRoute(builder: (c) => _ReportDetailScreen(title: title)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(grade, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// Internal Mock Screen for Report Detail
class _ReportDetailScreen extends StatelessWidget {
  final String title;
  const _ReportDetailScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text("$title Loading...", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
          ],
        ),
      ),
    );
  }
}