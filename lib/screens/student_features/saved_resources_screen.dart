import 'package:flutter/material.dart';

class SavedResourcesScreen extends StatelessWidget {
  const SavedResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Downloads", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFileCard("Maths Formulas.pdf", "2.5 MB", Icons.picture_as_pdf, Colors.red),
          _buildFileCard("Physics Notes Ch-1.docx", "1.2 MB", Icons.description, Colors.blue),
          _buildFileCard("Chemistry Periodic Table.jpg", "500 KB", Icons.image, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFileCard(String name, String size, IconData icon, Color color) {
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
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(size),
        trailing: const Icon(Icons.more_vert),
        onTap: () {},
      ),
    );
  }
}