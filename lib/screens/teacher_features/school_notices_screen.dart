import 'package:flutter/material.dart';

class SchoolNoticesScreen extends StatefulWidget {
  const SchoolNoticesScreen({super.key});

  @override
  State<SchoolNoticesScreen> createState() => _SchoolNoticesScreenState();
}

class _SchoolNoticesScreenState extends State<SchoolNoticesScreen> {
  // Dummy Data: Shuruwat mein ye notices dikhenge
  final List<Map<String, String>> _notices = [
    {
      "title": "Winter Vacation",
      "date": "20 Dec 2023",
      "tag": "HOLIDAY",
      "desc": "School will remain closed from 25th Dec to 5th Jan for winter break."
    },
    {
      "title": "Annual Sports Day",
      "date": "18 Dec 2023",
      "tag": "EVENT",
      "desc": "Sports day selection trials will begin from Monday. Ensure students are in proper uniform."
    },
    {
      "title": "Parent Teacher Meeting",
      "date": "15 Dec 2023",
      "tag": "IMPORTANT",
      "desc": "PTM for Class 10 is scheduled for this Saturday. Attendance is mandatory."
    },
  ];

  // Naya Notice Add Karne Ka Logic
  void _addNewNotice(String title, String desc, String tag) {
    setState(() {
      _notices.insert(0, {
        "title": title,
        "date": "Just Now",
        "tag": tag,
        "desc": desc,
      });
    });
  }

  // Notice Add Karne Wala Dialog Box
  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedTag = "URGENT";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Notice"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Notice Title", hintText: "e.g., Exam Schedule"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description", hintText: "Type details here..."),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                _addNewNotice(titleController.text, descController.text, selectedTag);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notice Published Successfully! 📢"), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            child: const Text("Publish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("School Board", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoticeDialog,
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add),
        label: const Text("New Notice"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return _buildNoticeCard(notice);
        },
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, String> notice) {
    Color tagColor;
    switch (notice['tag']) {
      case 'HOLIDAY': tagColor = Colors.blue; break;
      case 'EVENT': tagColor = Colors.orange; break;
      case 'IMPORTANT': tagColor = Colors.red; break;
      default: tagColor = Colors.teal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(notice['tag']!, style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Text(notice['date']!, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(notice['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(notice['desc']!, style: TextStyle(color: Colors.grey[600], height: 1.4)),
        ],
      ),
    );
  }
}