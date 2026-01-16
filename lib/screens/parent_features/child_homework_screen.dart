import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import '../../models/homework_model.dart';
import '../../models/student_model.dart';

class ChildHomeworkScreen extends StatefulWidget {
  final StudentModel child;

  const ChildHomeworkScreen({super.key, required this.child});

  @override
  State<ChildHomeworkScreen> createState() => _ChildHomeworkScreenState();
}

class _ChildHomeworkScreenState extends State<ChildHomeworkScreen> {
  final ParentService _parentService = ParentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("${widget.child.name}'s Homework", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<HomeworkModel>>(
        stream: _parentService.getChildHomework(widget.child.uid),
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

          final homeworkList = snapshot.data ?? [];

          if (homeworkList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No homework assigned', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          // Separate pending and completed homework
          final now = DateTime.now();
          final pending = homeworkList.where((h) => h.dueDate.isAfter(now)).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final overdue = homeworkList.where((h) => h.dueDate.isBefore(now)).toList()
            ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overdue.isNotEmpty) ...[
                  const Text("Overdue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 15),
                  ...overdue.map((hw) => _buildHomeworkCard(hw, isOverdue: true)),
                  const SizedBox(height: 30),
                ],
                if (pending.isNotEmpty) ...[
                  const Text("Upcoming", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...pending.map((hw) => _buildHomeworkCard(hw, isOverdue: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeworkCard(HomeworkModel homework, {required bool isOverdue}) {
    final isDueSoon = !isOverdue && homework.dueDate.difference(DateTime.now()).inDays <= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
            : isDueSoon
                ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5)
                : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      homework.subjectName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : isDueSoon
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOverdue ? 'Overdue' : isDueSoon ? 'Due Soon' : 'Active',
                  style: TextStyle(
                    color: isOverdue ? Colors.red : isDueSoon ? Colors.orange : Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (homework.description != null && homework.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              homework.description!,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Due: ${_formatDate(homework.dueDate)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                homework.teacherName,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (homework.attachmentUrls != null && homework.attachmentUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${homework.attachmentUrls!.length} attachment(s)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
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
