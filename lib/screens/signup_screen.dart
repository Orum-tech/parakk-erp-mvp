import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/school_service.dart';
import '../services/school_invitation_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'auth_wrapper.dart';

class SignupScreen extends StatefulWidget {
  final String userRole;

  const SignupScreen({super.key, required this.userRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _useInvitation = false;
  final _schoolService = SchoolService();
  final _invitationService = SchoolInvitationService();

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color gradientLight = const Color(0xFF64B5F6);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolCodeController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get role enum
      UserRole role = _getRoleEnum(widget.userRole);

      String? schoolCode;
      String? invitationId;

      // Validate school code or invitation
      if (_useInvitation) {
        if (_invitationCodeController.text.trim().isEmpty) {
          throw Exception('Please enter invitation code');
        }
        // Get invitation by ID (assuming invitation code is the ID)
        final invitation = await _invitationService.getInvitationById(
          _invitationCodeController.text.trim(),
        );
        if (invitation == null || !invitation.canAccept) {
          throw Exception('Invalid or expired invitation code');
        }
        if (invitation.email.toLowerCase() != _emailController.text.trim().toLowerCase()) {
          throw Exception('Invitation email does not match your email');
        }
        invitationId = invitation.invitationId;
      } else {
        if (_schoolCodeController.text.trim().isEmpty) {
          throw Exception('Please enter school code');
        }
        // Validate school code
        final school = await _schoolService.getSchoolByCode(
          _schoolCodeController.text.trim(),
        );
        if (school == null) {
          throw Exception('Invalid school code');
        }
        if (!school.isSubscriptionActive) {
          throw Exception('School subscription is not active');
        }
        schoolCode = _schoolCodeController.text.trim().toUpperCase();
      }

      // Call signup service
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: role,
        schoolCode: schoolCode,
        invitationId: invitationId,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to AuthWrapper root
        // AuthWrapper will detect auth state change and check onboarding
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


  UserRole _getRoleEnum(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
        return UserRole.parent;
      default:
        return UserRole.student;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Header
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, gradientLight],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Button
                        Material(
                          color: Colors.white.withOpacity(0.2),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign up as a ${widget.userRole}",
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. Form Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Full Name
                    _buildAestheticTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                      primaryColor: primaryBlue,
                      validator: AuthService.validateName,
                    ),
                    const SizedBox(height: 20),
                    
                    // Email
                    _buildAestheticTextField(
                      controller: _emailController,
                      label: "Email ID",
                      icon: Icons.email_outlined,
                      primaryColor: primaryBlue,
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 20),
                    
                    // Password
                    _buildAestheticTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
                      primaryColor: primaryBlue,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      validator: AuthService.validatePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 20),
                    
                    // Confirm Password
                    _buildAestheticTextField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      primaryColor: primaryBlue,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    const SizedBox(height: 20),
                    
                    // Toggle between school code and invitation
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _useInvitation = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_useInvitation ? primaryBlue : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'School Code',
                                  style: TextStyle(
                                    color: !_useInvitation ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _useInvitation = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _useInvitation ? primaryBlue : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Invitation',
                                  style: TextStyle(
                                    color: _useInvitation ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // School Code or Invitation Code
                    _buildAestheticTextField(
                      controller: _useInvitation ? _invitationCodeController : _schoolCodeController,
                      label: _useInvitation ? "Invitation Code" : "School Code",
                      icon: _useInvitation ? Icons.mail_outline : Icons.school_outlined,
                      primaryColor: primaryBlue,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _useInvitation
                              ? 'Please enter invitation code'
                              : 'Please enter school code';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // 3. Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 10,
                          shadowColor: primaryBlue.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                "Register",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 4. Already have an account? Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: TextStyle(color: Colors.grey[600])),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(userRole: widget.userRole),
                                    ),
                                  );
                                },
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAestheticTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
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
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey[400],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
