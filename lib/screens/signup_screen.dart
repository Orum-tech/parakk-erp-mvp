import 'package:flutter/material.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';
import 'login_screen.dart'; // ✅ Added Import for Login Screen

class SignupScreen extends StatelessWidget {
  final String userRole;

  const SignupScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    // Aesthetic Colors
    final Color primaryBlue = const Color(0xFF1565C0);
    final Color gradientLight = const Color(0xFF64B5F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header (Same as Login Screen for consistency)
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
                      Text(
                        "Create Account",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign up as a $userRole",
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
                  _buildAestheticTextField(label: "Full Name", icon: Icons.person_outline, primaryColor: primaryBlue),
                  const SizedBox(height: 20),
                  _buildAestheticTextField(
                    label: userRole == "Parent" ? "Mobile Number" : "Email ID", 
                    icon: userRole == "Parent" ? Icons.phone_android_rounded : Icons.email_outlined, 
                    primaryColor: primaryBlue
                  ),
                  const SizedBox(height: 20),
                  _buildAestheticTextField(label: "Password", icon: Icons.lock_outline, isPassword: true, primaryColor: primaryBlue),
                  const SizedBox(height: 20),
                  _buildAestheticTextField(label: "Confirm Password", icon: Icons.lock_outline, isPassword: true, primaryColor: primaryBlue),

                  const SizedBox(height: 40),

                  // 3. Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                         // After signup, navigate to respective dashboard
                        if (userRole == "Student") {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
                        } else if (userRole == "Teacher") {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherDashboard()));
                        } else if (userRole == "Parent") {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentDashboard()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 10,
                        shadowColor: primaryBlue.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. Already have an account? Login (Redirect Logic)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () {
                          // ✅ Navigate to Login Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen(userRole: userRole)),
                          );
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildAestheticTextField({required String label, required IconData icon, required Color primaryColor, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          suffixIcon: isPassword ? Icon(Icons.visibility_off_rounded, color: Colors.grey[400]) : null,
        ),
      ),
    );
  }
}