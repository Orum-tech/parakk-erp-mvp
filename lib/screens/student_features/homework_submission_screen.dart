import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/homework_service.dart';
import '../../models/homework_model.dart';

class HomeworkSubmissionScreen extends StatefulWidget {
  final HomeworkModel homework;

  const HomeworkSubmissionScreen({super.key, required this.homework});

  @override
  State<HomeworkSubmissionScreen> createState() => _HomeworkSubmissionScreenState();
}

class _HomeworkSubmissionScreenState extends State<HomeworkSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeworkService = HomeworkService();
  final _submissionController = TextEditingController();
  
  bool _isLoading = false;
  final List<String> _attachmentUrls = [];

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submissionController.text.trim().isEmpty && _attachmentUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide submission text or attach a file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _homeworkService.submitHomework(
        homeworkId: widget.homework.homeworkId,
        submissionText: _submissionController.text.trim().isEmpty 
            ? null 
            : _submissionController.text.trim(),
        attachmentUrls: _attachmentUrls.isEmpty ? null : _attachmentUrls,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Homework submitted successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.homework.isOverdue;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Submit Assignment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Homework Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isOverdue
                      ? Border.all(color: Colors.red, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.homework.subjectName,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "OVERDUE",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.homework.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.homework.description != null && widget.homework.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.homework.description!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 5),
                        Text(
                          widget.homework.teacherName,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 5),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(widget.homework.dueDate)}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (widget.homework.attachmentUrls != null && widget.homework.attachmentUrls!.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        "Attachments:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ...widget.homework.attachmentUrls!.map((url) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  url.split('/').last,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Submission Form
              const Text(
                "Your Submission",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Submission Text
              TextFormField(
                controller: _submissionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Type your answer or submission here...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 20),

              // Attachments
              if (_attachmentUrls.isNotEmpty) ...[
                const Text(
                  "Attached Files:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachmentUrls.map((url) {
                    return Chip(
                      label: Text(url.split('/').last),
                      onDeleted: () {
                        setState(() => _attachmentUrls.remove(url));
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Attach File Button
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement file picker and upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("File upload feature coming soon")),
                  );
                },
                icon: const Icon(Icons.attach_file, color: Color(0xFF1565C0)),
                label: const Text("Attach File (Optional)", style: TextStyle(color: Color(0xFF1565C0))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Assignment",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
