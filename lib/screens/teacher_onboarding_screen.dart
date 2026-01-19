import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/onboarding_service.dart';
import 'teacher_dashboard.dart';

class TeacherOnboardingScreen extends StatefulWidget {
  const TeacherOnboardingScreen({super.key});

  @override
  State<TeacherOnboardingScreen> createState() => _TeacherOnboardingScreenState();
}

class _TeacherOnboardingScreenState extends State<TeacherOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _onboardingService = OnboardingService();
  
  // Controllers
  final _employeeIdController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _departmentController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _specializationController = TextEditingController();

  // State variables
  final List<String> _selectedSubjects = [];
  final List<String> _selectedClassIds = [];
  String? _classTeacherClassId; // Single class where teacher is class teacher
  String? _selectedSubjectToAdd;
  String? _selectedClassToAdd;
  String? _selectedSectionToAdd;
  DateTime? _selectedJoiningDate;
  bool _isLoading = false;

  final Color primaryTeal = const Color(0xFF00897B);
  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Hindi',
    'History',
    'Geography',
    'Computer Science',
    'Physical Education',
    'Arts',
    'Economics',
    'Business Studies',
    'Accountancy',
  ];
  final List<String> _classes = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _departments = [
    'Mathematics',
    'Science',
    'English',
    'Social Studies',
    'Computer Science',
    'Physical Education',
    'Arts',
    'Languages',
    'Other',
  ];

  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedJoiningDate = picked);
    }
  }

  void _addSubject() {
    if (_selectedSubjectToAdd != null && !_selectedSubjects.contains(_selectedSubjectToAdd)) {
      setState(() {
        _selectedSubjects.add(_selectedSubjectToAdd!);
        _selectedSubjectToAdd = null;
      });
    }
  }

  void _removeSubject(String subject) {
    setState(() {
      _selectedSubjects.remove(subject);
    });
  }

  void _addClass() {
    if (_selectedClassToAdd != null && _selectedSectionToAdd != null) {
      final classId = 'class_${_selectedClassToAdd}_$_selectedSectionToAdd';
      if (!_selectedClassIds.contains(classId)) {
        setState(() {
          _selectedClassIds.add(classId);
          _selectedClassToAdd = null;
          _selectedSectionToAdd = null;
        });
      }
    }
  }

  void _removeClass(String classId) {
    setState(() {
      _selectedClassIds.remove(classId);
      if (_classTeacherClassId == classId) {
        _classTeacherClassId = null;
      }
    });
  }

  void _setClassTeacher(String classId) {
    setState(() {
      // Only one class can be class teacher at a time
      _classTeacherClassId = (_classTeacherClassId == classId) ? null : classId;
    });
  }

  String _getClassDisplayName(String classId) {
    // classId format: class_5_A
    final parts = classId.replaceFirst('class_', '').split('_');
    if (parts.length == 2) {
      return 'Class ${parts[0]}-${parts[1]}';
    }
    return classId;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject')),
      );
      return;
    }
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _onboardingService.completeTeacherOnboarding(
        employeeId: _employeeIdController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        subjects: _selectedSubjects,
        classIds: _selectedClassIds,
        classTeacherClassId: _classTeacherClassId,
        phoneNumber: _phoneNumberController.text.trim().isEmpty 
            ? null 
            : _phoneNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty 
            ? null 
            : _addressController.text.trim(),
        department: _departmentController.text.trim().isEmpty 
            ? null 
            : _departmentController.text.trim(),
        qualification: _qualificationController.text.trim().isEmpty 
            ? null 
            : _qualificationController.text.trim(),
        yearsOfExperience: _yearsOfExperienceController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_yearsOfExperienceController.text.trim()),
        joiningDate: _selectedJoiningDate,
        specialization: _specializationController.text.trim().isEmpty 
            ? null 
            : _specializationController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _schoolNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _yearsOfExperienceController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryTeal, const Color(0xFF4DB6AC)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Complete Your Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Help us set up your teacher account",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Form Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Employee ID (Required)
                      _buildTextField(
                        controller: _employeeIdController,
                        label: "Employee ID *",
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Employee ID is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // School Name (Required)
                      _buildTextField(
                        controller: _schoolNameController,
                        label: "School Name *",
                        icon: Icons.school_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'School name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Subjects Selection (Required)
                      _buildSubjectSelection(),
                      const SizedBox(height: 20),

                      // Classes Selection (Required)
                      _buildClassSelection(),
                      const SizedBox(height: 20),

                      // Department
                      _buildDropdown(
                        controller: _departmentController,
                        label: "Department",
                        icon: Icons.business_outlined,
                        items: _departments,
                      ),
                      const SizedBox(height: 20),

                      // Qualification
                      _buildTextField(
                        controller: _qualificationController,
                        label: "Qualification",
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Years of Experience
                      _buildTextField(
                        controller: _yearsOfExperienceController,
                        label: "Years of Experience",
                        icon: Icons.work_outline,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Joining Date
                      _buildDatePicker(),
                      const SizedBox(height: 20),

                      // Specialization
                      _buildTextField(
                        controller: _specializationController,
                        label: "Specialization",
                        icon: Icons.star_outline,
                      ),
                      const SizedBox(height: 20),

                      // Phone Number
                      _buildTextField(
                        controller: _phoneNumberController,
                        label: "Phone Number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Address
                      _buildTextField(
                        controller: _addressController,
                        label: "Address",
                        icon: Icons.home_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Complete Setup",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: Icon(icon, color: primaryTeal),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSubjectSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.subject_outlined, color: primaryTeal),
            const SizedBox(width: 8),
            const Text(
              "Subjects *",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildSubjectDropdown(),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSubjects.map((subject) {
              return Chip(
                label: Text(subject),
                onDeleted: () => _removeSubject(subject),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: primaryTeal.withOpacity(0.1),
                labelStyle: TextStyle(color: primaryTeal, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildClassSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.class_outlined, color: primaryTeal),
            const SizedBox(width: 8),
            const Text(
              "Classes *",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildClassDropdown(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSectionDropdown(),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _addClass,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedClassIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: _selectedClassIds.map((classId) {
                final isClassTeacher = _classTeacherClassId == classId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isClassTeacher ? primaryTeal : Colors.grey[300]!,
                      width: isClassTeacher ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: classId,
                              groupValue: _classTeacherClassId,
                              onChanged: (value) => _setClassTeacher(value!),
                              activeColor: primaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: isClassTeacher ? primaryTeal : Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getClassDisplayName(classId),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isClassTeacher ? primaryTeal : Colors.black87,
                                    ),
                                  ),
                                  if (isClassTeacher)
                                    Text(
                                      'Class Teacher',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: primaryTeal,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.grey[600],
                        onPressed: () => _removeClass(classId),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSubjectToAdd,
        decoration: InputDecoration(
          hintText: 'Select subject',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        items: _subjects.map((subject) {
          return DropdownMenuItem<String>(
            value: subject,
            child: Text(subject, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => _selectedSubjectToAdd = value);
        },
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedClassToAdd,
        decoration: InputDecoration(
          hintText: 'Class',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        items: _classes.map((classNum) {
          return DropdownMenuItem<String>(
            value: classNum,
            child: Text('Class $classNum', style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => _selectedClassToAdd = value);
        },
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSectionToAdd,
        decoration: InputDecoration(
          hintText: 'Section',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        items: _sections.map((section) {
          return DropdownMenuItem<String>(
            value: section,
            child: Text('Section $section', style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => _selectedSectionToAdd = value);
        },
      ),
    );
  }

  Widget _buildDropdown({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          icon: Icon(icon, color: primaryTeal),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? value) {
          controller.text = value ?? '';
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectJoiningDate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: primaryTeal),
            const SizedBox(width: 16),
            Text(
              _selectedJoiningDate == null
                  ? "Joining Date"
                  : DateFormat('dd MMM yyyy').format(_selectedJoiningDate!),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _selectedJoiningDate == null
                    ? Colors.grey[500]
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
