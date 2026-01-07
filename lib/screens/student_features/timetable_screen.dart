import 'package:flutter/material.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Weekly Schedule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1565C0),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Mon"), Tab(text: "Tue"), Tab(text: "Wed"),
              Tab(text: "Thu"), Tab(text: "Fri"), Tab(text: "Sat"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDayList(isActiveDay: true), // Monday (Active)
            _buildDayList(), _buildDayList(), _buildDayList(), _buildDayList(),
            const Center(child: Text("Weekend Mode On! 🌴")),
          ],
        ),
      ),
    );
  }

  Widget _buildDayList({bool isActiveDay = false}) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if(isActiveDay) 
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text("Today's Classes", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
        _buildClassCard("08:30 AM", "09:30 AM", "Mathematics", "Algebra - Ch 4", "Mrs. Radhika", Colors.orange, isLive: isActiveDay),
        _buildClassCard("09:30 AM", "10:30 AM", "Physics", "Laws of Motion", "Mr. Verma", Colors.blue),
        _buildClassCard("10:30 AM", "11:00 AM", "Break", "Lunch Time", "Cafeteria", Colors.grey, isBreak: true),
        _buildClassCard("11:00 AM", "12:00 PM", "Chemistry", "Periodic Table", "Ms. Anjali", Colors.purple),
        _buildClassCard("12:00 PM", "01:00 PM", "Computer Sci", "Lab Session", "Lab 2", Colors.indigo),
      ],
    );
  }

  Widget _buildClassCard(String start, String end, String subject, String topic, String teacher, Color color, {bool isBreak = false, bool isLive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(start, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(height: 40, width: 2, color: Colors.grey[300], margin: const EdgeInsets.symmetric(vertical: 5)),
              Text(end, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLive ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isLive ? Border.all(color: Colors.blue, width: 1.5) : null,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(subject, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isBreak ? Colors.grey : Colors.black87)),
                      if(isLive) 
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)), child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  if(!isBreak) ...[
                    const SizedBox(height: 5),
                    Text(topic, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(radius: 10, backgroundColor: color.withOpacity(0.1), child: Icon(Icons.person, size: 12, color: color)),
                        const SizedBox(width: 8),
                        Text(teacher, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}