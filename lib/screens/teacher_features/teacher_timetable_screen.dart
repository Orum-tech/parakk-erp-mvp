import 'package:flutter/material.dart';

class TeacherTimetableScreen extends StatelessWidget {
  const TeacherTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("My Schedule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [Tab(text: "Mon"), Tab(text: "Tue"), Tab(text: "Wed"), Tab(text: "Thu"), Tab(text: "Fri")],
          ),
        ),
        body: TabBarView(
          children: List.generate(5, (index) => _buildDaySchedule()),
        ),
      ),
    );
  }

  Widget _buildDaySchedule() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPeriod("08:30 - 09:30", "10-A", "Mathematics", Colors.orange),
        _buildPeriod("09:30 - 10:30", "9-B", "Mathematics", Colors.blue),
        _buildPeriod("10:30 - 11:00", "Free", "Break", Colors.grey, isBreak: true),
        _buildPeriod("11:00 - 12:00", "10-C", "Algebra", Colors.purple),
      ],
    );
  }

  Widget _buildPeriod(String time, String cls, String subject, Color color, {bool isBreak = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isBreak ? Colors.grey : Colors.black87)),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          if (!isBreak)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text("Class $cls", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}