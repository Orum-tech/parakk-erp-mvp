import 'package:flutter/material.dart';

class ClassSettingsScreen extends StatefulWidget {
  const ClassSettingsScreen({super.key});

  @override
  State<ClassSettingsScreen> createState() => _ClassSettingsScreenState();
}

class _ClassSettingsScreenState extends State<ClassSettingsScreen> {
  // State Variables
  bool _allowLateAttendance = true;
  bool _autoLockHomework = false;
  bool _muteGroupChat = false;
  bool _showRankToStudents = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Class Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Attendance & Homework", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSwitchTile(
            "Allow Late Attendance",
            "Students can mark attendance after 9:00 AM",
            _allowLateAttendance,
            (val) => setState(() => _allowLateAttendance = val),
          ),
          _buildSwitchTile(
            "Auto-Lock Homework",
            "Close submissions automatically after deadline",
            _autoLockHomework,
            (val) => setState(() => _autoLockHomework = val),
          ),

          const SizedBox(height: 30),
          const Text("Communication & Privacy", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSwitchTile(
            "Mute Class Group",
            "Only admins can send messages",
            _muteGroupChat,
            (val) => setState(() => _muteGroupChat = val),
          ),
          _buildSwitchTile(
            "Show Ranks to Students",
            "Display class rank in results card",
            _showRankToStudents,
            (val) => setState(() => _showRankToStudents = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool val, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        value: val,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF00897B),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}