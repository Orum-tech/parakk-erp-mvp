import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import '../../models/marks_model.dart';
import '../../models/student_model.dart';

class ChildResultsScreen extends StatefulWidget {
  final StudentModel child;

  const ChildResultsScreen({super.key, required this.child});

  @override
  State<ChildResultsScreen> createState() => _ChildResultsScreenState();
}

class _ChildResultsScreenState extends State<ChildResultsScreen> {
  final ParentService _parentService = ParentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("${widget.child.name}'s Results", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<MarksModel>>(
        stream: _parentService.getChildMarks(widget.child.uid),
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

          final marksList = snapshot.data ?? [];

          if (marksList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No results available yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          // Group marks by exam
          final Map<String, List<MarksModel>> marksByExam = {};
          for (var mark in marksList) {
            if (!marksByExam.containsKey(mark.examName)) {
              marksByExam[mark.examName] = [];
            }
            marksByExam[mark.examName]!.add(mark);
          }

          // Calculate overall statistics
          double totalPercentage = 0.0;
          int count = 0;
          for (var mark in marksList) {
            totalPercentage += mark.percentage;
            count++;
          }
          final overallPercentage = count > 0 ? totalPercentage / count : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Performance Card
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: overallPercentage >= 80
                          ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
                          : overallPercentage >= 60
                              ? [Colors.orange, Colors.orangeAccent]
                              : [Colors.red, Colors.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (overallPercentage >= 80 ? Colors.green : overallPercentage >= 60 ? Colors.orange : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("Overall Performance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 10),
                      Text(
                        "${overallPercentage.toStringAsFixed(1)}%",
                        style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${marksList.length} exam(s) completed",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Results by Exam
                ...marksByExam.entries.map((entry) {
                  final examName = entry.key;
                  final examMarks = entry.value;
                  
                  // Calculate exam average
                  double examTotal = 0.0;
                  for (var mark in examMarks) {
                    examTotal += mark.percentage;
                  }
                  final examAverage = examMarks.isNotEmpty ? examTotal / examMarks.length : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              examName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: examAverage >= 80
                                  ? Colors.green.withOpacity(0.1)
                                  : examAverage >= 60
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${examAverage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                color: examAverage >= 80
                                    ? Colors.green
                                    : examAverage >= 60
                                        ? Colors.orange
                                        : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ...examMarks.map((mark) => _buildMarksCard(mark)),
                      const SizedBox(height: 30),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarksCard(MarksModel mark) {
    final percentage = mark.percentage;
    final isPassing = mark.isPassing;
    final grade = mark.grade ?? mark.calculateGrade();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPassing ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mark.subjectName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  mark.examDate != null ? _formatDate(mark.examDate!) : 'Date not available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (mark.remarks != null && mark.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    mark.remarks!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${mark.marksObtained}/${mark.maxMarks}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPassing ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: isPassing ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
