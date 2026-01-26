import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../models/user_model.dart';
import 'role_selection_screen.dart';
import 'signup_screen.dart';
import 'auth_wrapper.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String userRole;

  const LoginScreen({super.key, required this.userRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color gradientLight = const Color(0xFF64B5F6);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Convert string role to UserRole enum
      UserRole? expectedRole;
      switch (widget.userRole.toLowerCase()) {
        case 'student':
          expectedRole = UserRole.student;
          break;
        case 'teacher':
          expectedRole = UserRole.teacher;
          break;
        case 'parent':
          expectedRole = UserRole.parent;
          break;
        case 'schooladmin':
          expectedRole = UserRole.schoolAdmin;
          break;
      }

      // Call login service with role validation
      final user = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        expectedRole: expectedRole,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user?.name ?? ''}!'),
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Big Curved Header
              Container(
                height: 280,
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
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${widget.userRole} ${loc.login}",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 2. Form Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Email
                    _buildAestheticTextField(
                      controller: _emailController,
                      label: loc.email,
                      icon: Icons.email_outlined,
                      primaryColor: primaryBlue,
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 20),
                    
                    // Password
                    _buildAestheticTextField(
                      controller: _passwordController,
                      label: loc.password,
                      icon: Icons.lock_outline_rounded,
                      primaryColor: primaryBlue,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      validator: AuthService.validatePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          loc.forgotPassword,
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 3. Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 10,
                          shadowColor: primaryBlue.withOpacity(0.4),
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
                            : Text(
                                loc.login,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  
                    const SizedBox(height: 20),
                    
                    // 4. Don't have an account? Sign up (hide for SchoolAdmin)
                    if (widget.userRole.toLowerCase() != 'schooladmin')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${loc.dontHaveAccount} ", style: TextStyle(color: Colors.grey[600])),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignupScreen(userRole: widget.userRole),
                                      ),
                                    );
                                  },
                            child: Text(
                              loc.signup,
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 10),
                    
                    // 5. Choose different role
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RoleSelectionScreen(),
                                ),
                                (route) => false,
                              );
                            },
                      child: Text(
                        "Choose different role",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ),
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
