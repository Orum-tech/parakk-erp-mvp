import 'package:flutter/material.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _simulateUpload(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Upload Assignment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Take Photo"),
              onTap: () { Navigator.pop(context); _showSuccess(context); },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.orange),
              title: const Text("Choose PDF"),
              onTap: () { Navigator.pop(context); _showSuccess(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File uploaded successfully!"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Assignments", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1565C0),
          tabs: const [
            Tab(text: "To Do"),
            Tab(text: "Submitted"),
            Tab(text: "Graded"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(isPending: true),
          _buildList(isPending: false),
          const Center(child: Text("No Graded Assignments")),
        ],
      ),
    );
  }

  Widget _buildList({required bool isPending}) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard("Mathematics", "Algebra Ex 4.2", "Tomorrow", Colors.orange, 0.4, isPending),
        if(isPending) _buildCard("Physics", "Laws of Motion", "18 Dec", Colors.blue, 0.1, isPending),
      ],
    );
  }

  Widget _buildCard(String sub, String title, String date, Color color, double prog, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(sub, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const Spacer(),
              if(isPending) Text("Due: $date", style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if(isPending)
            ElevatedButton(
              onPressed: () => _simulateUpload(context, title),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text("Upload", style: TextStyle(color: Colors.white)),
            )
        ],
      ),
    );
  }
}