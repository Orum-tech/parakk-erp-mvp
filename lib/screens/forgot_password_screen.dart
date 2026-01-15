import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color gradientLight = const Color(0xFF64B5F6);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Don't worry, we'll help you reset it",
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

              // 2. Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    if (_emailSent)
                      // Success Message
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green[700],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Email Sent!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "We've sent a password reset link to\n${_emailController.text.trim()}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Please check your inbox and follow the instructions to reset your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Email Input Form
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enter your email address and we'll send you a link to reset your password.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Email Field
                          _buildAestheticTextField(
                            controller: _emailController,
                            label: "Email ID",
                            icon: Icons.email_outlined,
                            primaryColor: primaryBlue,
                            keyboardType: TextInputType.emailAddress,
                            validator: AuthService.validateEmail,
                          ),
                        ],
                      ),

                    const SizedBox(height: 30),

                    // 3. Reset Password Button
                    if (!_emailSent)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
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
                              : const Text(
                                  "Send Reset Link",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                    if (_emailSent) ...[
                      const SizedBox(height: 20),
                      // Back to Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryBlue, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Back to Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    
                    // 4. Remember your password?
                    if (!_emailSent)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Remember your password? ", 
                            style: TextStyle(color: Colors.grey[600])),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
    TextInputType? keyboardType,
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
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
