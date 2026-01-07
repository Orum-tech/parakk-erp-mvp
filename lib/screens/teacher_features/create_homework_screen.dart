import 'package:flutter/material.dart';

class CreateHomeworkScreen extends StatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedClass = "10-A";
  String? _selectedSubject = "Mathematics";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text("Assign Homework", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdowns
            Row(
              children: [
                Expanded(
                  child: _buildDropdown("Class", ["10-A", "10-B", "9-A"], _selectedClass, (v) => setState(() => _selectedClass = v)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDropdown("Subject", ["Maths", "Science", "English"], _selectedSubject, (v) => setState(() => _selectedSubject = v)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel("Title / Topic"),
            TextField(
              controller: _titleController,
              decoration: _inputStyle("e.g. Algebra Ex 4.2"),
            ),
            
            const SizedBox(height: 20),
            _buildLabel("Instructions"),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: _inputStyle("Enter detailed instructions here..."),
            ),

            const SizedBox(height: 20),
            _buildLabel("Submission Deadline"),
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context, 
                  initialDate: _dueDate, 
                  firstDate: DateTime.now(), 
                  lastDate: DateTime(2026)
                );
                if(picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text("${_dueDate.day}/${_dueDate.month}/${_dueDate.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File Attached: assignment.pdf")));
              },
              icon: const Icon(Icons.attach_file, color: Colors.teal),
              label: const Text("Attach File (Optional)", style: TextStyle(color: Colors.teal)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            if(_titleController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title"), backgroundColor: Colors.red));
              return;
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Homework Assigned Successfully! 📚"), backgroundColor: Colors.green));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Assign to Class", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? val, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)));

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}