import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("E-Library", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.bookmark_border))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recommended for You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildBookCover("Science Vol 1", "Class 10", Colors.blue),
                  _buildBookCover("History World", "Class 10", Colors.brown),
                  _buildBookCover("Maths Algebra", "Class 10", Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildCategory("Textbooks", Icons.menu_book),
                _buildCategory("Journals", Icons.article),
                _buildCategory("Exam Prep", Icons.assignment),
                _buildCategory("Fiction", Icons.auto_stories),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBookCover(String title, String sub, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(color: color.withOpacity(0.8), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: const Center(child: Icon(Icons.book, color: Colors.white, size: 50)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                  Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategory(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}