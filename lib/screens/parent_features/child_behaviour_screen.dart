import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import '../../models/behaviour_log_model.dart';
import '../../models/student_model.dart';

class ChildBehaviourScreen extends StatelessWidget {
  final StudentModel child;

  const ChildBehaviourScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final parentService = ParentService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("${child.name}'s Behaviour", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<BehaviourLogModel>>(
        stream: parentService.getChildBehaviourLogs(child.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No behaviour logs available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          // Group by type for summary
          int positive = 0, negative = 0, neutral = 0, appreciation = 0;
          for (var log in logs) {
            switch (log.behaviourType) {
              case BehaviourType.positive:
                positive++;
                break;
              case BehaviourType.negative:
                negative++;
                break;
              case BehaviourType.neutral:
                neutral++;
                break;
              case BehaviourType.appreciation:
                appreciation++;
                break;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard("Positive", positive.toString(), Colors.green, Icons.thumb_up)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSummaryCard("Appreciation", appreciation.toString(), Colors.blue, Icons.star)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard("Neutral", neutral.toString(), Colors.grey, Icons.remove_circle_outline)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSummaryCard("Negative", negative.toString(), Colors.red, Icons.thumb_down)),
                  ],
                ),

                const SizedBox(height: 30),

                // Behaviour Logs
                const Text("Recent Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                ...logs.map((log) => _buildBehaviourCard(log)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBehaviourCard(BehaviourLogModel log) {
    Color typeColor;
    IconData typeIcon;
    String typeText;

    switch (log.behaviourType) {
      case BehaviourType.positive:
        typeColor = Colors.green;
        typeIcon = Icons.thumb_up;
        typeText = 'Positive';
        break;
      case BehaviourType.negative:
        typeColor = Colors.red;
        typeIcon = Icons.thumb_down;
        typeText = 'Negative';
        break;
      case BehaviourType.appreciation:
        typeColor = Colors.blue;
        typeIcon = Icons.star;
        typeText = 'Appreciation';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.remove_circle_outline;
        typeText = 'Neutral';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: typeColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(log.date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeText,
                  style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            log.remark,
            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
          ),
          if (log.subjectName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.book, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  log.subjectName!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (log.teacherName != null) ...[
                  const Spacer(),
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    log.teacherName!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
