import 'package:flutter/material.dart';

class LeaveRequestsScreen extends StatelessWidget {
  const LeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text("Leave Applications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildRequestCard(context, "Vikram Singh", "Medical Leave", "2 Days (25-26 Oct)", "Pending"),
          _buildRequestCard(context, "Sneha Gupta", "Family Function", "1 Day (28 Oct)", "Approved"),
          _buildRequestCard(context, "Rohan Das", "Sick Leave", "3 Days (20-22 Oct)", "Rejected"),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String name, String reason, String duration, String status) {
    Color statusColor = status == "Pending" ? Colors.orange : (status == "Approved" ? Colors.green : Colors.red);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text("$reason • $duration", style: TextStyle(color: Colors.grey[600])),
          if (status == "Pending") ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: (){}, child: const Text("Reject", style: TextStyle(color: Colors.red)))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("Approve"))),
              ],
            )
          ]
        ],
      ),
    );
  }
}