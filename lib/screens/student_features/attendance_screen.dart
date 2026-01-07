import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Attendance Insights", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Hero Circular Indicator
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Overall Attendance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        const Text("92%", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: const Text("Excellent Pace 🚀", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 100, width: 100,
                    child: Stack(
                      children: [
                        const Center(child: Icon(Icons.check_circle_outline, color: Colors.white24, size: 100)),
                        Center(child: CircularProgressIndicator(value: 0.92, strokeWidth: 8, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.white))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. Stats Grid
            Row(
              children: [
                _buildStatCard("Total Days", "142", Colors.blue),
                const SizedBox(width: 15),
                _buildStatCard("Present", "131", Colors.green),
                const SizedBox(width: 15),
                _buildStatCard("Absent", "11", Colors.redAccent),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // 3. Calendar View Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("October 2023", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.calendar_month_rounded, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 15),
            
            // 4. Daily List
            _buildDayTile("24 Oct", "Tue", "Present", Colors.green),
            _buildDayTile("23 Oct", "Mon", "Present", Colors.green),
            _buildDayTile("21 Oct", "Sat", "Absent (Medical)", Colors.redAccent),
            _buildDayTile("20 Oct", "Fri", "Present", Colors.green),
            _buildDayTile("19 Oct", "Thu", "Holiday", Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(String date, String day, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(day, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}