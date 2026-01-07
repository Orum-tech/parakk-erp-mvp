// FILE: lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Aesthetic Colors
    final Color bgWhite = const Color(0xFFF8F9FD);
    final Color primaryBlue = const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: bgWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // 1. Modern Header
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 5,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Parakk ERP",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        "Choose your identity",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 50),

              // 2. Animated Role Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildAestheticCard(
                      context,
                      title: "Student",
                      subtitle: "View assignments & results",
                      icon: Icons.school_rounded,
                      role: "Student",
                    ),
                    const SizedBox(height: 20),
                    _buildAestheticCard(
                      context,
                      title: "Teacher",
                      subtitle: "Manage class & attendance",
                      icon: Icons.auto_stories_rounded,
                      role: "Teacher",
                    ),
                    const SizedBox(height: 20),
                    _buildAestheticCard(
                      context,
                      title: "Parent",
                      subtitle: "Track child's progress",
                      icon: Icons.family_restroom_rounded,
                      role: "Parent",
                    ),
                  ],
                ),
              ),

              // Footer
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Secure & Private • v1.0",
                    style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAestheticCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String role,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(userRole: role)),
        );
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Accent Bar
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
            const SizedBox(width: 24),
            
            // Icon Bubble
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 28),
            ),
            const SizedBox(width: 20),
            
            // Text Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Icon(Icons.arrow_forward_rounded, color: Colors.blueGrey[200]),
            ),
          ],
        ),
      ),
    );
  }
}