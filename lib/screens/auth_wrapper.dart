import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/settings_service.dart';
import '../models/user_model.dart';
import 'role_selection_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';
import 'student_onboarding_screen.dart';
import 'teacher_onboarding_screen.dart';
import 'parent_features/link_child_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565C0),
              ),
            ),
          );
        }

        // If user is logged in, navigate to appropriate dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getCurrentUserWithData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final user = userSnapshot.data!;
                // Check if biometric is enabled - if so, show biometric auth first
                return FutureBuilder<bool>(
                  future: SettingsService().getBiometricEnabled(),
                  builder: (context, bioSnapshot) {
                    if (bioSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      );
                    }

                    // If biometric is enabled, show biometric auth screen
                    if (bioSnapshot.data == true) {
                      return _BiometricAuthScreen(
                        user: user,
                      );
                    }

                    // Otherwise proceed to onboarding check
                    return _DashboardRouter(user: user);
                  },
                );
              }

              return const RoleSelectionScreen();
            },
          );
        }

        // If user is not logged in, show role selection
        return const RoleSelectionScreen();
      },
    );
  }
}

// Biometric Authentication Screen
class _BiometricAuthScreen extends StatefulWidget {
  final UserModel user;

  const _BiometricAuthScreen({required this.user});

  @override
  State<_BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<_BiometricAuthScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isAuthenticating = true;
  bool _authSuccess = false;

  @override
  void initState() {
    super.initState();
    _authenticateWithBiometric();
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final result = await _settingsService.authenticateWithBiometric();
      
      if (mounted) {
        if (result['success']) {
          setState(() {
            _authSuccess = true;
            _isAuthenticating = false;
          });
          // Wait a moment then proceed
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          setState(() => _isAuthenticating = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Biometric authentication failed'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAuthenticating)
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 50,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Biometric Authentication',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please authenticate to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              )
            else if (_authSuccess)
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Authentication Successful',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Authentication Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _authenticateWithBiometric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      // Disable biometric and proceed
                      await _settingsService.setBiometricEnabled(false);
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                    child: const Text(
                      'Continue Without Biometric',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Router - handles onboarding checks
class _DashboardRouter extends StatelessWidget {
  final UserModel user;

  const _DashboardRouter({required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService().isOnboardingComplete(
        user.uid,
        user.roleString,
      ),
      builder: (context, onboardingSnapshot) {
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565C0),
              ),
            ),
          );
        }

        final isOnboardingComplete = onboardingSnapshot.data ?? false;

        if (!isOnboardingComplete) {
          // Redirect to onboarding based on role
          if (user.role == UserRole.student) {
            return const StudentOnboardingScreen();
          } else if (user.role == UserRole.teacher) {
            return const TeacherOnboardingScreen();
          } else if (user.role == UserRole.parent) {
            // Show link child screen for parents (optional onboarding)
            return const LinkChildScreen();
          }
        }

        return _getDashboard(user.role);
      },
    );
  }

  Widget _getDashboard(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.parent:
        return const ParentDashboard();
    }
  }
}

