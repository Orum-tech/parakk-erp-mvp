import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/student_model.dart';
import '../../services/parent_service.dart';
import 'chat_detail_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ParentService _parentService = ParentService();

  StudentModel? _student;
  Map<String, String>? _classTeacherInfo;
  bool _isLoading = true;

  // Default admin contact (can be loaded from Firestore settings if available)
  static const String adminEmail = 'admin@parakk-school.com';
  static const String adminPhone = '+91-1234567890';
  static const String supportEmail = 'support@parakk-school.com';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load student data
      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });

        // Load class teacher info if student has a class
        if (_student?.classId != null) {
          final teacherInfo = await _parentService.getClassTeacherInfo(_student!.classId!);
          setState(() {
            _classTeacherInfo = teacherInfo;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading support data: $e');
    } finally {
      setState(() => _isLoading = false);
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

Future<void> _sendEmail(String email, {String? subject}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
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

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: const Text(
          'Please describe the issue you encountered. You can contact support via email or call the admin office.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmail(supportEmail, subject: 'App Issue Report');
            },
            child: const Text('Email Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Help & Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("How can we help you?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Class Teacher Contact Card
            if (_classTeacherInfo != null && _classTeacherInfo!['email'] != null)
              _buildClassTeacherCard(
                teacherName: _classTeacherInfo!['teacherName'] ?? 'Class Teacher',
                email: _classTeacherInfo!['email']!,
                phone: _classTeacherInfo!['phone'] ?? '',
                teacherId: _classTeacherInfo!['teacherId'] ?? '',
              ),

            // School Admin Contact
            _buildSupportOption(
              "Call School Admin",
              _classTeacherInfo?['phone'] ?? adminPhone,
              Icons.call,
              Colors.green,
              () => _makePhoneCall(_classTeacherInfo?['phone'] ?? adminPhone),
            ),


            // Email Support
            _buildSupportOption(
              "Email Support",
              supportEmail,
              Icons.email,
              Colors.blue,
              () => _sendEmail(supportEmail, subject: 'Student Support Request'),
            ),

            // Report Issue
            _buildSupportOption(
              "Report an Issue",
              "App bugs or problems",
              Icons.bug_report,
              Colors.redAccent,
              _showReportIssueDialog,
            ),
            
            const SizedBox(height: 30),
            const Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            _buildFaqTile(
              "How to pay fees online?",
              "Currently, fee payment is available through the 'Pay Fees' option in your dashboard. You can view your fee details and make payments online. If you face any issues, please contact the admin office.",
            ),
            
            _buildFaqTile(
              "How to apply for leave?",
              "You can apply for leave through the 'Leave Application' section in your dashboard. Fill in the required details including dates and reason, then submit. Your class teacher will review and approve your leave request.",
            ),
            
            _buildFaqTile(
              "Where to find exam syllabus?",
              "Exam syllabus and study materials are available in the 'Library' section of your dashboard. You can also check the 'Academic Reports' section for exam schedules and datesheets.",
            ),
            
            _buildFaqTile(
              "How to view my attendance?",
              "Your attendance records are available in the 'Analytics' section. You can view daily attendance, monthly statistics, and overall attendance percentage. The dashboard also shows your attendance summary.",
            ),
            
            _buildFaqTile(
              "How to contact my teacher?",
              "You can contact your class teacher using the 'Contact Class Teacher' option above. For subject-specific queries, you can use the 'Chat' feature in the Connect tab to message your teachers directly.",
            ),
            
            _buildFaqTile(
              "Where can I see my exam results?",
              "Your exam results and marks are available in the 'Results' section. You can view subject-wise marks, overall CGPA, and download your marksheet. Academic reports with detailed performance analysis are also available.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildClassTeacherCard({
    required String teacherName,
    required String email,
    required String phone,
    required String teacherId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Class Teacher",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacherName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Contact Details
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                // Chat Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            teacherId: teacherId,
                            teacherName: teacherName,
                            teacherEmail: email,
                            subject: 'Class Teacher',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text("Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Email Button
                if (email.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendEmail(
                        email,
                        subject: 'Message for ${_student?.name ?? 'Student'} - ${_student?.className ?? 'N/A'}',
                      ),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text("Email"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.blue, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}