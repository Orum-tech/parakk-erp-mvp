import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/homework_service.dart';
import '../../models/homework_model.dart';
import 'create_homework_screen.dart';
import 'homework_submissions_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _homeworkService = HomeworkService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Homework & Assignments", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateHomeworkScreen()),
          );
        },
        label: const Text("Create New"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<HomeworkModel>>(
        stream: _homeworkService.getTeacherHomework(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final homeworkList = snapshot.data ?? [];

          if (homeworkList.isEmpty) {
            return const Center(
              child: Text(
                "No homework assigned yet.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
              padding: const EdgeInsets.all(15),
            itemCount: homeworkList.length,
              itemBuilder: (context, index) {
              final hw = homeworkList[index];
              return _buildHomeworkCard(hw);
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeworkCard(HomeworkModel hw) {
    final isOverdue = hw.isOverdue;
    final submissionPercentage = hw.submissionPercentage;
    final submittedCount = hw.submittedCount ?? 0;
    final totalStudents = hw.totalStudents ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeworkSubmissionsScreen(homework: hw),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                      hw.subjectName,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                              ),
                            ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOverdue ? 'Overdue' : 'Active',
                      style: TextStyle(
                        color: isOverdue ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                hw.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
              const SizedBox(height: 5),
                        Text(
                hw.className,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(hw.dueDate)}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (hw.description != null && hw.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  hw.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
                        const SizedBox(height: 15),
                        // Submission Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                      Text(
                        "Submissions",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        "$submittedCount${totalStudents > 0 ? '/$totalStudents' : ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                    value: totalStudents > 0 ? submissionPercentage / 100 : 0,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.green,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
              ),
                      ],
                    ),
                  ),
            ),
    );
  }
}