import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Help Center", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
             _showDialog(context, "Terms", "By using this app, you agree to follow school discipline guidelines.");
          }),
          _buildSectionTile("Contact Support", Icons.support_agent, () {
             _showDialog(context, "Support", "Email us at: support@parakk.com\nCall: +91-1234567890");
          }),
          const SizedBox(height: 20),
          const Text("FAQs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          const ExpansionTile(title: Text("How to reset password?"), children: [Padding(padding: EdgeInsets.all(15.0), child: Text("Go to login screen and click 'Forgot Password'."))]),
          const ExpansionTile(title: Text("How to contact teacher?"), children: [Padding(padding: EdgeInsets.all(15.0), child: Text("Use the 'Chat' tab to message your class teacher directly."))]),
        ],
      ),
    );
  }

  Widget _buildSectionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
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
}