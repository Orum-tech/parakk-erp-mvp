import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_admin_model.dart';
import '../models/school_model.dart';
import '../services/school_admin_service.dart';
import '../services/school_service.dart';
import '../services/auth_service.dart';
import '../widgets/school_context_indicator.dart';

class SchoolAdminDashboard extends StatefulWidget {
  const SchoolAdminDashboard({super.key});

  @override
  State<SchoolAdminDashboard> createState() => _SchoolAdminDashboardState();
}

class _SchoolAdminDashboardState extends State<SchoolAdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SchoolAdminService _adminService = SchoolAdminService();
  final SchoolService _schoolService = SchoolService();
  final AuthService _authService = AuthService();

  SchoolAdminModel? _admin;
  SchoolModel? _school;
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load admin data
      final admin = await _adminService.getSchoolAdminById(user.uid);
      if (admin == null) return;

      // Load school data
      final school = await _schoolService.getSchoolById(admin.schoolId);
      if (school == null) return;

      // Load statistics
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('schoolId', isEqualTo: admin.schoolId)
          .get();
      
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .where('schoolId', isEqualTo: admin.schoolId)
          .get();
      
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('schoolId', isEqualTo: admin.schoolId)
          .get();

      setState(() {
        _admin = admin;
        _school = school;
        _totalStudents = studentsSnapshot.docs.length;
        _totalTeachers = teachersSnapshot.docs.length;
        _totalClasses = classesSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF1565C0),
          ),
        ),
      );
    }

    if (_admin == null || _school == null) {
      return Scaffold(
        body: Center(
          child: Text('Error loading dashboard data'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
              child: Icon(Icons.admin_panel_settings, color: const Color(0xFF1565C0)),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SchoolNameHeader(),
                Text(
                  "School Admin",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500
                  ),
                ),
                Text(
                  _admin?.name ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 18
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          SchoolContextIndicator(),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey[700]),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1565C0), const Color(0xFF64B5F6)],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _school!.schoolName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${_school!.schoolCode}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getSubscriptionStatusText(_school!.subscriptionStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Students',
                    value: _totalStudents.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Teachers',
                    value: _totalTeachers.toString(),
                    icon: Icons.person_outline,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Classes',
                    value: _totalClasses.toString(),
                    icon: Icons.class_,
                    color: const Color(0xFFFF6F00),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  title: 'User Management',
                  icon: Icons.people_outline,
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User Management - Coming Soon')),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'Class Management',
                  icon: Icons.class_outlined,
                  color: const Color(0xFF2E7D32),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class Management - Coming Soon')),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'Subscription',
                  icon: Icons.payment,
                  color: const Color(0xFFFF6F00),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subscription Management - Coming Soon')),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'School Settings',
                  icon: Icons.settings,
                  color: const Color(0xFF7B1FA2),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('School Settings - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubscriptionStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'ACTIVE';
      case SubscriptionStatus.trial:
        return 'TRIAL';
      case SubscriptionStatus.expired:
        return 'EXPIRED';
      case SubscriptionStatus.suspended:
        return 'SUSPENDED';
      case SubscriptionStatus.cancelled:
        return 'CANCELLED';
    }
  }
}
