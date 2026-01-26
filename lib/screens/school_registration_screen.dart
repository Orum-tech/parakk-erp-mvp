import 'package:flutter/material.dart';
import '../services/school_service.dart';
import '../services/auth_service.dart';
import '../services/school_admin_service.dart';
import '../models/user_model.dart';
import '../models/school_admin_model.dart';
import 'auth_wrapper.dart';

class SchoolRegistrationScreen extends StatefulWidget {
  const SchoolRegistrationScreen({super.key});

  @override
  State<SchoolRegistrationScreen> createState() => _SchoolRegistrationScreenState();
}

class _SchoolRegistrationScreenState extends State<SchoolRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _principalNameController = TextEditingController();
  final _principalEmailController = TextEditingController();
  final _principalPhoneController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _schoolService = SchoolService();
  final _authService = AuthService();
  final _adminService = SchoolAdminService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  
  final Color primaryBlue = const Color(0xFF1565C0);

  @override
  void dispose() {
    _schoolNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _principalNameController.dispose();
    _principalEmailController.dispose();
    _principalPhoneController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Create school
      final school = await _schoolService.createSchool(
        schoolName: _schoolNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        principalName: _principalNameController.text.trim().isNotEmpty
            ? _principalNameController.text.trim()
            : null,
        principalEmail: _principalEmailController.text.trim().isNotEmpty
            ? _principalEmailController.text.trim()
            : null,
        principalPhone: _principalPhoneController.text.trim().isNotEmpty
            ? _principalPhoneController.text.trim()
            : null,
      );

      // Step 2: Create admin account
      final adminUser = await _authService.signUp(
        email: _adminEmailController.text.trim(),
        password: _adminPasswordController.text.trim(),
        name: _adminNameController.text.trim(),
        role: UserRole.schoolAdmin,
        schoolId: school.schoolId,
      );

      if (adminUser == null) {
        throw Exception('Failed to create admin account');
      }

      // Step 3: Create school admin record
      await _adminService.createSchoolAdmin(
        uid: adminUser.uid,
        name: _adminNameController.text.trim(),
        email: _adminEmailController.text.trim(),
        schoolId: school.schoolId,
        adminRole: AdminRole.superAdmin,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School registered successfully! School Code: ${school.schoolCode}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navigate to AuthWrapper
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Your School'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            // Validate only current step's fields
            bool isValid = true;
            String? errorMessage;
            
            if (_currentStep == 0) {
              // Step 1: School Information
              if (_schoolNameController.text.trim().isEmpty) {
                errorMessage = 'School name is required';
                isValid = false;
              } else {
                final emailError = AuthService.validateEmail(_emailController.text);
                if (emailError != null) {
                  errorMessage = emailError;
                  isValid = false;
                } else if (_phoneController.text.trim().isEmpty) {
                  errorMessage = 'Phone number is required';
                  isValid = false;
                } else if (_addressController.text.trim().isEmpty) {
                  errorMessage = 'Address is required';
                  isValid = false;
                }
              }
            } else if (_currentStep == 1) {
              // Step 2: Principal Information (optional) - always valid
              isValid = true;
            } else if (_currentStep == 2) {
              // Step 3: Admin Account
              if (_adminNameController.text.trim().isEmpty) {
                errorMessage = 'Admin name is required';
                isValid = false;
              } else {
                final emailError = AuthService.validateEmail(_adminEmailController.text);
                if (emailError != null) {
                  errorMessage = emailError;
                  isValid = false;
                } else {
                  final passwordError = AuthService.validatePassword(_adminPasswordController.text);
                  if (passwordError != null) {
                    errorMessage = passwordError;
                    isValid = false;
                  } else if (_confirmPasswordController.text.trim().isEmpty) {
                    errorMessage = 'Please confirm your password';
                    isValid = false;
                  } else if (_adminPasswordController.text != _confirmPasswordController.text) {
                    errorMessage = 'Passwords do not match';
                    isValid = false;
                  }
                }
              }
            }
            
            if (!isValid && errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
              );
              return;
            }
            
            // All validations passed - proceed
            if (_currentStep < 2) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              // Last step - register school
              _registerSchool();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              Navigator.pop(context);
            }
          },
          steps: [
            // Step 1: School Information
            Step(
              title: const Text('School Information'),
              content: Column(
                children: [
                  _buildTextField(
                    controller: _schoolNameController,
                    label: 'School Name *',
                    icon: Icons.school,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'School name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'School Email *',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthService.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number *',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Phone number is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address *',
                    icon: Icons.location_on,
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Address is required'
                        : null,
                  ),
                ],
              ),
            ),
            // Step 2: Principal Information (Optional)
            Step(
              title: const Text('Principal Information'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.indexed : StepState.disabled),
              content: Column(
                children: [
                  _buildTextField(
                    controller: _principalNameController,
                    label: 'Principal Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _principalEmailController,
                    label: 'Principal Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        return AuthService.validateEmail(value);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _principalPhoneController,
                    label: 'Principal Phone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            // Step 3: Admin Account
            Step(
              title: const Text('Admin Account'),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
              content: Column(
                children: [
                  _buildTextField(
                    controller: _adminNameController,
                    label: 'Admin Name *',
                    icon: Icons.person,
                    validator: AuthService.validateName,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _adminEmailController,
                    label: 'Admin Email *',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthService.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _adminPasswordController,
                    label: 'Password *',
                    icon: Icons.lock,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    validator: AuthService.validatePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password *',
                    icon: Icons.lock,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please confirm your password';
                      }
                      if (value != _adminPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You will be the first admin of this school. A unique school code will be generated after registration.',
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_currentStep == 2 ? 'Register' : 'Continue'),
                    ),
                  ),
                ],
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        // Step 1: School Information - check all required fields
        final schoolNameValid = _schoolNameController.text.trim().isNotEmpty;
        final emailValid = _emailController.text.trim().isNotEmpty;
        final phoneValid = _phoneController.text.trim().isNotEmpty;
        final addressValid = _addressController.text.trim().isNotEmpty;
        
        return schoolNameValid && emailValid && phoneValid && addressValid;
      case 1:
        // Step 2: Principal Information - optional, always valid
        return true;
      case 2:
        // Step 3: Admin Account - check all required fields
        final adminNameValid = _adminNameController.text.trim().isNotEmpty;
        final adminEmailValid = _adminEmailController.text.trim().isNotEmpty;
        final passwordValid = _adminPasswordController.text.trim().isNotEmpty;
        final confirmPasswordValid = _confirmPasswordController.text.trim().isNotEmpty;
        final passwordsMatch = _adminPasswordController.text.trim() == 
            _confirmPasswordController.text.trim();
        
        return adminNameValid && adminEmailValid && passwordValid && 
               confirmPasswordValid && passwordsMatch;
      default:
        return false;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
