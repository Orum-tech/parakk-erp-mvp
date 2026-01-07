import 'package:flutter/material.dart';

class SyllabusTrackerScreen extends StatefulWidget {
  const SyllabusTrackerScreen({super.key});

  @override
  State<SyllabusTrackerScreen> createState() => _SyllabusTrackerScreenState();
}

class _SyllabusTrackerScreenState extends State<SyllabusTrackerScreen> {
  final List<Map<String, dynamic>> _chapters = [
    {"name": "Real Numbers", "done": true},
    {"name": "Polynomials", "done": true},
    {"name": "Linear Equations", "done": false},
    {"name": "Quadratic Equations", "done": false},
    {"name": "Arithmetic Progressions", "done": false},
    {"name": "Triangles", "done": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text("Mathematics Syllabus", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _chapters.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: CheckboxListTile(
              activeColor: const Color(0xFF00897B),
              title: Text(
                _chapters[index]['name'],
                style: TextStyle(
                  decoration: _chapters[index]['done'] ? TextDecoration.lineThrough : null,
                  color: _chapters[index]['done'] ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _chapters[index]['done'],
              onChanged: (val) => setState(() => _chapters[index]['done'] = val),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Text(
          "${_chapters.where((c) => c['done']).length} of ${_chapters.length} Chapters Completed",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
        ),
      ),
    );
  }
}