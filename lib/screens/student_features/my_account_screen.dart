import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/student_model.dart';
import '../../services/storage_service.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  StudentModel? _student;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPicture = false;

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        final student = StudentModel.fromDocument(studentDoc);
        setState(() {
          _student = student;
          _phoneController.text = student.phoneNumber ?? '';
          _addressController.text = student.address ?? '';
          _selectedDateOfBirth = student.dateOfBirth;
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

  Future<void> _uploadProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) return;

      setState(() => _isUploadingPicture = true);

      // Upload to Firebase Storage
      final imageFile = File(image.path);
      final downloadUrl = await _storageService.uploadProfilePicture(
        imageFile,
        onProgress: (progress) {
          // Could show progress if needed
        },
      );

      // Update user document in Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'profilePictureUrl': downloadUrl,
        });

        // Reload student data
        await _loadStudentData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPicture = false);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 15)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_student == null) return;

    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update student data in Firestore
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

      if (_selectedDateOfBirth != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(_selectedDateOfBirth!);
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Reload student data
      await _loadStudentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully! ✅"),
            backgroundColor: Colors.green,
          ),
        );
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

  String _getClassName() {
    if (_student?.className != null && _student?.section != null) {
      return '${_student!.className}-${_student!.section}';
    } else if (_student?.classId != null) {
      final parts = _student!.classId!.replaceFirst('class_', '').split('_');
      if (parts.length == 2) {
        return 'Class ${parts[0]}-${parts[1]}';
      }
    }
    return 'Class';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Profile Picture with Upload Button
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1565C0), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _student?.profilePictureUrl != null
                          ? NetworkImage(_student!.profilePictureUrl!)
                          : null,
                      child: _student?.profilePictureUrl == null
                          ? Text(
                              _student?.name.isNotEmpty == true
                                  ? _student!.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPicture ? null : _uploadProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isUploadingPicture ? Colors.grey : const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingPicture
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _student?.name ?? 'Student',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "${_getClassName()}${_student?.rollNumber != null ? ' | Roll No. ${_student!.rollNumber}' : ''}",
              style: const TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 30),

            // 2. Profile Fields
            // Name - Read Only
            _buildReadOnlyField(
              "Full Name",
              _student?.name ?? '',
              Icons.person,
            ),
            
            // Email - Read Only
            _buildReadOnlyField(
              "Email ID",
              _student?.email ?? '',
              Icons.email,
            ),
            
            // Phone Number - Editable
            _buildEditableField(
              "Phone Number",
              _phoneController,
              Icons.phone,
              TextInputType.phone,
            ),
            
            // Date of Birth - Editable with Date Picker
            _buildDateField(
              "Date of Birth",
              _selectedDateOfBirth,
              Icons.cake,
            ),
            
            // Address - Editable
            _buildEditableField(
              "Address",
              _addressController,
              Icons.location_on,
              TextInputType.streetAddress,
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: TextEditingController(text: value),
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon,
    TextInputType keyboardType, {
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: _selectDateOfBirth,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
          child: Text(
            date != null ? _formatDate(date) : 'Select Date of Birth',
            style: TextStyle(
              color: date != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}