import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../forgot_password_screen.dart';

class ParentHelpSupportScreen extends StatelessWidget {
  const ParentHelpSupportScreen({super.key});

  static const String supportEmail = 'support@parakk-school.com';
  static const String supportPhone = '+91-1234567890';

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Parent Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (context.mounted) {
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
        title: const Text("Help & Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTile("Privacy Policy", Icons.privacy_tip_outlined, () {
            _showDialog(context, "Privacy Policy", "We value your privacy. All your data is encrypted and secure with Parakk ERP.");
          }),
          _buildSectionTile("Terms & Conditions", Icons.description_outlined, () {
             _showDialog(context, "Terms & Conditions", "By using this app, you agree to follow school policies and guidelines.");
          }),
          _buildSectionTile("Contact Support", Icons.support_agent, () {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text("Contact Support"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Get in touch with our support team:"),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.blue),
                      title: const Text("Email"),
                      subtitle: Text(supportEmail),
                      onTap: () {
                        Navigator.pop(c);
                        _sendEmail(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.call, color: Colors.green),
                      title: const Text("Phone"),
                      subtitle: Text(supportPhone),
                      onTap: () {
                        Navigator.pop(c);
                        _makePhoneCall(context);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text("FAQs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          _buildPasswordResetFaq(context),
          _buildFaqTile(
            "How to view my child's attendance?",
            "Go to the Dashboard tab and tap on the Attendance card. You can view daily, weekly, and monthly attendance reports for your child.",
          ),
          _buildFaqTile(
            "How to pay fees?",
            "Navigate to the Fees tab in the bottom navigation. You can view outstanding fees and make payments through the integrated payment gateway.",
          ),
          _buildFaqTile(
            "How to contact my child's teacher?",
            "Go to the Connect tab and select 'Class Teacher'. You can send messages directly to your child's class teacher through the chat feature.",
          ),
          _buildFaqTile(
            "How to submit a leave request?",
            "On the Dashboard, tap on the Leave feature. Fill in the leave details including dates and reason, then submit for teacher approval.",
          ),
          _buildFaqTile(
            "How to view my child's homework?",
            "On the Dashboard, tap on the Homework card. You can see all assigned homework, due dates, and submission status.",
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E40AF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  Widget _buildPasswordResetFaq(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ExpansionTile(
        title: const Text("How to reset password?", style: TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You can reset your password by clicking the button below. We'll send you a reset link to your email.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Reset Password",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
