import 'package:flutter/material.dart';

class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Announcements", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNoticeCard(
            "Rain Holiday Declared", 
            "Due to heavy rainfall alert by IMD, school will remain closed tomorrow.", 
            "URGENT", Colors.red, "Today, 10:00 AM"
          ),
          _buildNoticeCard(
            "Annual Sports Day", 
            "Registration open for 100m sprint and Football. Contact Mr. Singh.", 
            "EVENT", Colors.blue, "Yesterday"
          ),
          _buildNoticeCard(
            "Exam Schedule Released", 
            "Mid-term datesheet is now available in Results section.", 
            "ACADEMIC", Colors.purple, "20 Oct"
          ),
          _buildNoticeCard(
            "Fee Payment Reminder", 
            "Last date for Q2 fee submission is 30th Oct to avoid late fines.", 
            "ADMIN", Colors.orange, "18 Oct"
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(String title, String body, String tag, Color color, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                  child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(body, style: TextStyle(color: Colors.grey[600], height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }
}