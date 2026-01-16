import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/onboarding_service.dart';
import 'student_dashboard.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _onboardingService = OnboardingService();
  
  // Controllers
  final _rollNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();

  // State variables
  String? _selectedClass; // 1-10
  String? _selectedSection; // A-D
  DateTime? _selectedDateOfBirth;
  String? _selectedBloodGroup;
  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF1565C0);
  final List<String> _classes = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both class and section')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create classId from selected class and section
      final classId = 'class_${_selectedClass}_$_selectedSection';
      final className = 'Class $_selectedClass';
      final section = _selectedSection!;

      await _onboardingService.completeStudentOnboarding(
        rollNumber: _rollNumberController.text.trim(),
        classId: classId,
        className: className,
        section: section,
        phoneNumber: _phoneNumberController.text.trim().isEmpty 
            ? null 
            : _phoneNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty 
            ? null 
            : _addressController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        bloodGroup: _selectedBloodGroup,
        emergencyContact: _emergencyContactController.text.trim().isEmpty 
            ? null 
            : _emergencyContactController.text.trim(),
        parentName: _parentNameController.text.trim().isEmpty 
            ? null 
            : _parentNameController.text.trim(),
        parentEmail: _parentEmailController.text.trim().isEmpty 
            ? null 
            : _parentEmailController.text.trim().toLowerCase(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentDashboard()),
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
    _rollNumberController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _bloodGroupController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
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
                      colors: [primaryBlue, const Color(0xFF64B5F6)],
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
                          "Help us set up your student account",
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
                      // Roll Number (Required)
                      _buildTextField(
                        controller: _rollNumberController,
                        label: "Roll Number *",
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Roll number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Class and Section Selection (Required)
                      Row(
                        children: [
                          Expanded(
                            child: _buildClassDropdown(),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildSectionDropdown(),
                          ),
                        ],
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
                      const SizedBox(height: 20),

                      // Date of Birth
                      _buildDatePicker(),
                      const SizedBox(height: 20),

                      // Blood Group
                      _buildBloodGroupDropdown(),
                      const SizedBox(height: 20),

                      // Emergency Contact
                      _buildTextField(
                        controller: _emergencyContactController,
                        label: "Emergency Contact",
                        icon: Icons.emergency_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Parent Name
                      _buildTextField(
                        controller: _parentNameController,
                        label: "Parent/Guardian Name",
                        icon: Icons.family_restroom_outlined,
                      ),
                      const SizedBox(height: 20),
                      
                      // Parent Email
                      _buildTextField(
                        controller: _parentEmailController,
                        label: "Parent/Guardian Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
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
                      const SizedBox(height: 30),
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
          icon: Icon(icon, color: primaryBlue),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedClass,
        decoration: InputDecoration(
          icon: Icon(Icons.class_outlined, color: primaryBlue),
          labelText: "Class *",
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
        items: _classes.map((classNum) {
          return DropdownMenuItem<String>(
            value: classNum,
            child: Text('Class $classNum'),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => _selectedClass = value);
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a class';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSection,
        decoration: InputDecoration(
          icon: Icon(Icons.people_outline, color: primaryBlue),
          labelText: "Section *",
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
        items: _sections.map((section) {
          return DropdownMenuItem<String>(
            value: section,
            child: Text('Section $section'),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => _selectedSection = value);
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a section';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: primaryBlue),
            const SizedBox(width: 16),
            Text(
              _selectedDateOfBirth == null
                  ? "Date of Birth"
                  : DateFormat('dd MMM yyyy').format(_selectedDateOfBirth!),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _selectedDateOfBirth == null
                    ? Colors.grey[500]
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBloodGroup,
        decoration: InputDecoration(
          icon: Icon(Icons.bloodtype_outlined, color: primaryBlue),
          labelText: "Blood Group",
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
        items: _bloodGroups.map((group) {
          return DropdownMenuItem<String>(
            value: group,
            child: Text(group),
          );
        }).toList(),
        onChanged: (String? value) {
          setState(() => _selectedBloodGroup = value);
        },
      ),
    );
  }
}
