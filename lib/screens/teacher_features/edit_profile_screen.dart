import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for inputs
  final TextEditingController _nameController = TextEditingController(text: "Mrs. Radhika Gupta");
  final TextEditingController _phoneController = TextEditingController(text: "+91 98765 43210");
  final TextEditingController _emailController = TextEditingController(text: "radhika.g@parakk.edu");
  final TextEditingController _bioController = TextEditingController(text: "Mathematics Teacher | Class 10-A Class Teacher | 8 Years Experience");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () {
              // Simulate Save
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile Updated Successfully! ✅"), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Pic Edit
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF00897B), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildLabel("Full Name"),
            _buildTextField(_nameController, Icons.person_outline),
            
            _buildLabel("Mobile Number"),
            _buildTextField(_phoneController, Icons.phone_android_rounded),
            
            _buildLabel("Email ID"),
            _buildTextField(_emailController, Icons.email_outlined),
            
            _buildLabel("Professional Bio"),
            _buildTextField(_bioController, Icons.info_outline, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        filled: true,
        fillColor: const Color(0xFFF0F4F4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}