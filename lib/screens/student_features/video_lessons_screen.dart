import 'package:flutter/material.dart';

class VideoLessonsScreen extends StatelessWidget {
  const VideoLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Video Lessons", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Featured Video
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage('https://img.freepik.com/free-vector/online-education-concept_23-2148533319.jpg'), // Mock Thumbnail
                fit: BoxFit.cover,
                opacity: 0.7,
              ),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Recommended: Algebra Basics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),

          // Subject List
          const Text("Browse by Subject", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildSubjectTile("Mathematics", "12 Chapters", Icons.functions, Colors.orange),
          _buildSubjectTile("Physics", "8 Chapters", Icons.flash_on, Colors.blue),
          _buildSubjectTile("Chemistry", "10 Chapters", Icons.science, Colors.purple),
          _buildSubjectTile("English", "15 Chapters", Icons.language, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(String subject, String chapters, IconData icon, Color color) {
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
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(chapters),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}