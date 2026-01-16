import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/student_model.dart';
import '../../services/parent_service.dart';

class ClassTeacherContactScreen extends StatefulWidget {
  final StudentModel child;

  const ClassTeacherContactScreen({super.key, required this.child});

  @override
  State<ClassTeacherContactScreen> createState() => _ClassTeacherContactScreenState();
}

class _ClassTeacherContactScreenState extends State<ClassTeacherContactScreen> {
  final ParentService _parentService = ParentService();
  Map<String, String>? _teacherInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    setState(() => _isLoading = true);
    try {
      final teacherInfo = await _parentService.getClassTeacherInfo(widget.child.classId ?? '');
      setState(() => _teacherInfo = teacherInfo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teacher info: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Regarding ${widget.child.name} - ${widget.child.className ?? 'N/A'}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("Class Teacher - ${widget.child.className ?? 'N/A'}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teacherInfo == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Class teacher information not available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Teacher Info Card
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _teacherInfo!['teacherName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Class Teacher",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_teacherInfo!['email'] != null && _teacherInfo!['email']!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                _teacherInfo!['email']!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Contact Actions
                      if (_teacherInfo!['email'] != null && _teacherInfo!['email']!.isNotEmpty)
                        _buildContactButton(
                          title: "Send Email",
                          subtitle: _teacherInfo!['email']!,
                          icon: Icons.email_outlined,
                          color: Colors.blue,
                          onTap: () => _sendEmail(_teacherInfo!['email']!),
                        ),

                      const SizedBox(height: 15),

                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  "Student Information",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow("Name", widget.child.name),
                            const SizedBox(height: 10),
                            _buildInfoRow("Class", "${widget.child.className ?? 'N/A'} - ${widget.child.section ?? 'N/A'}"),
                            if (widget.child.rollNumber != null) ...[
                              const SizedBox(height: 10),
                              _buildInfoRow("Roll Number", widget.child.rollNumber!),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You can contact the class teacher via email for any questions regarding your child's academic progress, attendance, or behavior.",
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildContactButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
