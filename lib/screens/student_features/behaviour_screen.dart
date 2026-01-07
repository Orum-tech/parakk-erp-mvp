import 'package:flutter/material.dart';

class BehaviourScreen extends StatelessWidget {
  const BehaviourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Behaviour Log", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTimelineItem("Positive", "Helped a classmate in Science Lab.", "Mrs. Radhika", "22 Oct", Colors.green, isFirst: true),
          _buildTimelineItem("Negative", "Talking continuously during Math lecture.", "Mr. Verma", "15 Oct", Colors.redAccent),
          _buildTimelineItem("Appreciation", "Submitted assignment well before deadline.", "Ms. Anjali", "10 Oct", Colors.blue),
          _buildTimelineItem("Neutral", "Forgot Textbook.", "Mrs. Das", "05 Oct", Colors.orange, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String type, String remark, String teacher, String date, Color color, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if(!isFirst) Container(width: 2, height: 20, color: Colors.grey[300]),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                child: Container(height: 10, width: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ),
              if(!isLast) Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(remark, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("By: $teacher", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}