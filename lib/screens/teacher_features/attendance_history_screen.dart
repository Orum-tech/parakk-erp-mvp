import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text("Attendance Register", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMonthHeader("October 2023"),
          _buildRecordTile("24 Oct", "Tue", "95% Present", Colors.green),
          _buildRecordTile("23 Oct", "Mon", "92% Present", Colors.green),
          _buildRecordTile("21 Oct", "Sat", "85% Present", Colors.orange),
          _buildRecordTile("20 Oct", "Fri", "98% Present", Colors.green),
          
          const SizedBox(height: 20),
          _buildMonthHeader("September 2023"),
          _buildRecordTile("30 Sep", "Sat", "Holiday", Colors.grey),
          _buildRecordTile("29 Sep", "Fri", "90% Present", Colors.green),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildRecordTile(String date, String day, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Column(children: [Text(date, style: const TextStyle(fontWeight: FontWeight.bold)), Text(day, style: const TextStyle(fontSize: 10))]),
              ),
              const SizedBox(width: 15),
              Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}