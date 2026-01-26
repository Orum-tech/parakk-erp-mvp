import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/settings_service.dart';
import '../services/school_context_service.dart';
import '../services/school_service.dart';
import '../models/user_model.dart';
import 'role_selection_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';
import 'school_admin_dashboard.dart';
import 'student_onboarding_screen.dart';
import 'teacher_onboarding_screen.dart';
import 'parent_features/link_child_screen.dart';
import 'school_selection_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  
  // Cache the authorization state loading future to prevent rebuild loops
  Future<Map<String, dynamic>>? _userDataFuture;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize with current user if exists
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userDataFuture = _loadUserData(_currentUser!);
    }
  }

  // Combined data loading to fetch everything needed for routing once
  Future<Map<String, dynamic>> _loadUserData(User firebaseUser) async {
    try {
      final userModel = await _authService.getCurrentUserWithData();
      
      if (userModel == null) {
        return {'status': 'no_profile'};
      }

      // 1. School Context Validation (if not super admin)
      Map<String, dynamic> schoolContext = {'hasValidSchool': true};
      if (userModel.role != UserRole.superAdmin) {
        schoolContext = await _validateSchoolContext(userModel);
        if (schoolContext['needsSchoolSelection'] == true || schoolContext['hasValidSchool'] == false) {
          return {
            'status': 'school_issue',
            'user': userModel,
            'schoolContext': schoolContext
          };
        }
      }

      // 2. Biometric Check
      final biometricEnabled = await SettingsService().getBiometricEnabled();
      if (biometricEnabled) {
         return {
          'status': 'biometric_required',
          'user': userModel,
        };
      }

      // 3. Onboarding Check
      final onboardingComplete = await OnboardingService().isOnboardingComplete(
        userModel.uid, 
        userModel.roleString
      );

      return {
        'status': 'ready',
        'user': userModel,
        'onboardingComplete': onboardingComplete
      };

    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _validateSchoolContext(UserModel user) async {
    final schoolContextService = SchoolContextService();
    final schoolService = SchoolService();

    try {
      if (user.schoolId.isEmpty) {
        return {'hasValidSchool': false, 'needsSchoolSelection': false};
      }

      final school = await schoolService.getSchoolById(user.schoolId);
      if (school == null || !school.isSubscriptionActive) {
        return {'hasValidSchool': false, 'needsSchoolSelection': false};
      }

      await schoolContextService.setSchoolContext(user.schoolId);
      return {'hasValidSchool': true, 'needsSchoolSelection': false};
    } catch (e) {
      return {'hasValidSchool': false, 'needsSchoolSelection': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const _LoadingScreen();
        }

        final firebaseUser = snapshot.data;

        // If logged out
        if (firebaseUser == null) {
          _currentUser = null;
          _userDataFuture = null;
          return const RoleSelectionScreen();
        }

        // If user changed or first load, trigger data load
        if (_currentUser?.uid != firebaseUser.uid || _userDataFuture == null) {
          _currentUser = firebaseUser;
          _userDataFuture = _loadUserData(firebaseUser);
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, userSnapshot) {
             if (userSnapshot.connectionState == ConnectionState.waiting) {
               return const _LoadingScreen();
             }

             if (userSnapshot.hasError) {
               return Scaffold(body: Center(child: Text('Error: ${userSnapshot.error}')));
             }

             final data = userSnapshot.data;
             if (data == null || data['status'] == 'no_profile') {
               // Fallback if auth exists but no firestore data (rare zombie case handled in signup but good backup)
               return const RoleSelectionScreen();
             }

             // Handle States
             switch (data['status']) {
               case 'school_issue':
                 final schoolCtx = data['schoolContext'];
                 if (schoolCtx['needsSchoolSelection'] == true) {
                   return SchoolSelectionScreen(schoolIds: schoolCtx['schoolIds'] ?? []);
                 }
                 return _SchoolErrorScreen();
                
               case 'biometric_required':
                 return _BiometricAuthScreen(user: data['user']);

               case 'ready':
                  final UserModel user = data['user'];
                  final bool onboardingComplete = data['onboardingComplete'];

                  if (!onboardingComplete) {
                     switch (user.role) {
                       case UserRole.student: return const StudentOnboardingScreen();
                       case UserRole.teacher: return const TeacherOnboardingScreen();
                       case UserRole.parent: return const LinkChildScreen();
                       default: break; // Others might not have specific onboarding
                     }
                  }
                  return _getDashboard(user.role);
                  
               case 'error':
                 return Scaffold(
                   body: Center(
                     child: Text('Error loading profile: ${data['error']}'),
                   ),
                 );
                 
               default:
                 return const RoleSelectionScreen();
             }
          },
        );
      },
    );
  }

  Widget _getDashboard(UserRole role) {
    switch (role) {
      case UserRole.student: return const StudentDashboard();
      case UserRole.teacher: return const TeacherDashboard();
      case UserRole.parent: return const ParentDashboard();
      case UserRole.schoolAdmin: return const SchoolAdminDashboard();
      case UserRole.superAdmin: 
        return const Scaffold(body: Center(child: Text('Super Admin Dashboard - Coming Soon')));
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      ),
    );
  }
}

class _SchoolErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'School Not Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your account is not linked to a school.\nPlease contact your administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await AuthService().logout();
                // Navigation will be handled by the stream builder in AuthWrapper
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

// Biometric Authentication Screen (Copied and adapted from original)
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
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            // Success - Push Dashboard
            // Since AuthWrapper determines view based on state, we can just return a "Authenticated" state widget or similar, 
            // but simpler here might be simply replacing this widget in the tree or better yet,
            // managing the "biometric passed" state in the parent. 
            // However, to keep it simple without complex state management callback:
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => _DashboardAfterBiometric(user: widget.user),
              ),
            );
          }
        } else {
          setState(() => _isAuthenticating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Biometric authentication failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
       if(mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-using the UI from previous file for consistency
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isAuthenticating 
            ? const CircularProgressIndicator(color: Color(0xFF1565C0))
            : _authSuccess 
                ? const Icon(Icons.check_circle, size: 60, color: Colors.green)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const Text('Authentication Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 20),
                       ElevatedButton(onPressed: _authenticateWithBiometric, child: const Text('Try Again')),
                       TextButton(
                         onPressed: () async {
                           await _settingsService.setBiometricEnabled(false);
                           // Trigger rebuild in parent technically needed, but here we can just push dashboard
                           if(mounted) {
                             Navigator.of(context).pushReplacement(
                               MaterialPageRoute(builder: (context) => _DashboardAfterBiometric(user: widget.user)),
                             );
                           }
                         }, 
                         child: const Text('Continue with Password')
                       )
                    ],
                  ),
      ),
    );
  }
}

class _DashboardAfterBiometric extends StatelessWidget {
  final UserModel user;
  const _DashboardAfterBiometric({required this.user});
  
  @override
   Widget build(BuildContext context) {
    // Logic to check onboarding again would be redundant if we trust the parent, 
    // but safe to do simply:
    return FutureBuilder<bool>(
      future: OnboardingService().isOnboardingComplete(user.uid, user.roleString),
      builder: (context, snapshot) {
         if(!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
         if(snapshot.data == false) {
             if (user.role == UserRole.student) return const StudentOnboardingScreen();
             if (user.role == UserRole.teacher) return const TeacherOnboardingScreen();
             if (user.role == UserRole.parent) return const LinkChildScreen();
         }
         
        switch (user.role) {
          case UserRole.student: return const StudentDashboard();
          case UserRole.teacher: return const TeacherDashboard();
          case UserRole.parent: return const ParentDashboard();
          case UserRole.schoolAdmin: return const SchoolAdminDashboard();
          default: return const Scaffold(body: Center(child: Text('Dashboard')));
        }
      }
    );
   }
}
