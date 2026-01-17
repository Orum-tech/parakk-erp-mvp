import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
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
                // Check if onboarding is complete
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

              // If user exists in Auth but not in Firestore, logout and redirect to login
              return const RoleSelectionScreen();
            },
          );
        }

        // User is not logged in, show role selection
        return const RoleSelectionScreen();
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

