import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';

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
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color gradientLight = const Color(0xFF64B5F6);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get role enum
      UserRole role = _getRoleEnum(widget.userRole);

      // Call signup service
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: role,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to appropriate dashboard
        _navigateToDashboard(role);
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

  void _navigateToDashboard(UserRole role) {
    Widget dashboard;
    switch (role) {
      case UserRole.student:
        dashboard = const StudentDashboard();
        break;
      case UserRole.teacher:
        dashboard = const TeacherDashboard();
        break;
      case UserRole.parent:
        dashboard = const ParentDashboard();
        break;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
    );
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
                    const SizedBox(height: 20),
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
