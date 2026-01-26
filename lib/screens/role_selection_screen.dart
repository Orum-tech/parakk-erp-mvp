import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'school_registration_screen.dart';
import 'login_screen.dart';
import '../services/localization_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1, // Reduced from 0.15 to 0.1 to keep end <= 1.0
            0.5 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
              child: Column(
                children: [
                  // Logo with modern design
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Parakk ERP',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.selectRole,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Role Cards Section with animations
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Opacity(
                          opacity: _animations[0].value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _animations[0].value.clamp(0.0, 1.0))),
                            child: _buildModernCard(
                              context,
                              title: localizations.student,
                              subtitle: localizations.studentDesc,
                              icon: Icons.person_rounded,
                              gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                              role: "Student",
                              index: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _animations[1].value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _animations[1].value.clamp(0.0, 1.0))),
                            child: _buildModernCard(
                              context,
                              title: localizations.teacher,
                              subtitle: localizations.teacherDesc,
                              icon: Icons.auto_stories_rounded,
                              gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
                              role: "Teacher",
                              index: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _animations[2].value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _animations[2].value.clamp(0.0, 1.0))),
                            child: _buildModernCard(
                              context,
                              title: localizations.parent,
                              subtitle: localizations.parentDesc,
                              icon: Icons.family_restroom_rounded,
                              gradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                              role: "Parent",
                              index: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _animations[3].value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _animations[3].value.clamp(0.0, 1.0))),
                            child: _buildModernCard(
                              context,
                              title: "School Admin",
                              subtitle: "Manage your school's operations and users",
                              icon: Icons.admin_panel_settings_rounded,
                              gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                              role: "SchoolAdmin",
                              index: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _animations[4].value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - _animations[4].value.clamp(0.0, 1.0))),
                            child: _buildModernCard(
                              context,
                              title: "Register School",
                              subtitle: "Create a new school account",
                              icon: Icons.add_business_rounded,
                              gradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                              role: "RegisterSchool",
                              index: 4,
                              isSpecial: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Modern Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context).securePrivate,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String role,
    required int index,
    bool isSpecial = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (role == "RegisterSchool") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SchoolRegistrationScreen(),
              ),
            );
          } else if (role == "SchoolAdmin") {
            // School Admin should login directly (admin account created during school registration)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(userRole: role),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SignupScreen(userRole: role),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient background accent
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient[0].withOpacity(0.1),
                        gradient[1].withOpacity(0.05),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              
              // Content
              Row(
                children: [
                  // Icon Container with gradient
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                    ),
                  ),

                  // Text Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow Icon with gradient
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}