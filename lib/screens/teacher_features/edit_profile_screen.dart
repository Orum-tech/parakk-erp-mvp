import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/teacher_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TeacherModel? _teacher;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for inputs
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        final teacher = TeacherModel.fromDocument(teacherDoc);
        setState(() {
          _teacher = teacher;
          _phoneController.text = teacher.phoneNumber ?? '';
          _addressController.text = teacher.address ?? '';
          _qualificationController.text = teacher.qualification ?? '';
          _specializationController.text = teacher.specialization ?? '';
          _yearsOfExperienceController.text = teacher.yearsOfExperience?.toString() ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_teacher == null) return;

    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update teacher data in Firestore
      final updateData = <String, dynamic>{};
      
      if (_phoneController.text.trim().isNotEmpty) {
        updateData['phoneNumber'] = _phoneController.text.trim();
      } else {
        updateData['phoneNumber'] = null;
      }

      if (_addressController.text.trim().isNotEmpty) {
        updateData['address'] = _addressController.text.trim();
      } else {
        updateData['address'] = null;
      }

      if (_qualificationController.text.trim().isNotEmpty) {
        updateData['qualification'] = _qualificationController.text.trim();
      } else {
        updateData['qualification'] = null;
      }

      if (_specializationController.text.trim().isNotEmpty) {
        updateData['specialization'] = _specializationController.text.trim();
      } else {
        updateData['specialization'] = null;
      }

      if (_yearsOfExperienceController.text.trim().isNotEmpty) {
        final years = int.tryParse(_yearsOfExperienceController.text.trim());
        if (years != null && years >= 0) {
          updateData['yearsOfExperience'] = years;
        }
      } else {
        updateData['yearsOfExperience'] = null;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Reload teacher data
      await _loadTeacherData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_teacher == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('Teacher data not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("SAVE", style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF00897B).withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: const Color(0xFF00897B)),
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

            // Name - Read Only
            _buildLabel("Full Name"),
            _buildReadOnlyField(_teacher!.name, Icons.person_outline),
            
            // Email - Read Only
            _buildLabel("Email ID"),
            _buildReadOnlyField(_teacher!.email, Icons.email_outlined),
            
            // Employee ID - Read Only (if exists)
            if (_teacher!.employeeId != null) ...[
              _buildLabel("Employee ID"),
              _buildReadOnlyField(_teacher!.employeeId!, Icons.badge_outlined),
            ],
            
            // Phone Number - Editable
            _buildLabel("Mobile Number"),
            _buildTextField(_phoneController, Icons.phone_android_rounded, TextInputType.phone),
            
            // Address - Editable
            _buildLabel("Address"),
            _buildTextField(_addressController, Icons.location_on, TextInputType.streetAddress, maxLines: 2),
            
            // Qualification - Editable
            _buildLabel("Qualification"),
            _buildTextField(_qualificationController, Icons.school_outlined, TextInputType.text),
            
            // Specialization - Editable
            _buildLabel("Specialization"),
            _buildTextField(_specializationController, Icons.workspace_premium_outlined, TextInputType.text),
            
            // Years of Experience - Editable
            _buildLabel("Years of Experience"),
            _buildTextField(_yearsOfExperienceController, Icons.calendar_today_outlined, TextInputType.number),
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

  Widget _buildTextField(TextEditingController controller, IconData icon, TextInputType keyboardType, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        filled: true,
        fillColor: const Color(0xFFF0F4F4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildReadOnlyField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00897B)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}