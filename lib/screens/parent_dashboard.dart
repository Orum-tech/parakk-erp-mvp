import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../services/parent_service.dart';
import '../services/auth_service.dart';
import 'parent_features/child_attendance_screen.dart';
import 'parent_features/child_homework_screen.dart';
import 'parent_features/child_results_screen.dart';
import 'parent_features/child_fees_screen.dart';
import 'parent_features/child_behaviour_screen.dart';
import 'parent_features/notices_screen.dart';
import 'parent_features/events_screen.dart';
import 'parent_features/parent_profile_screen.dart';
import 'parent_features/parent_ai_assistant_screen.dart';
import 'parent_features/class_teacher_contact_screen.dart';
import 'parent_features/admin_office_contact_screen.dart';
import 'parent_features/leave_request_screen.dart';
import 'parent_features/notifications_screen.dart';
import '../services/notification_service.dart';
import 'placeholder_screen.dart';
import 'role_selection_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  // Premium Royal Blue Palette (Trustworthy & Clean)
  final Color kPrimaryColor = const Color(0xFF1E40AF); // Deep Royal Blue
  final Color kSecondaryColor = const Color(0xFF3B82F6); // Bright Blue
  final Color kBackgroundColor = const Color(0xFFF8FAFC); // Slate 50 (Very Light Grey)
  final Color kCardColor = Colors.white;

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ParentService _parentService = ParentService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Data state
  UserModel? _parent;
  List<StudentModel> _children = [];
  StudentModel? _selectedChild;
  Map<String, dynamic>? _attendanceStats;
  Map<String, dynamic>? _feeSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get parent data
      final parentData = await _authService.getCurrentUserWithData();
      setState(() => _parent = parentData);

      // Get children
      final children = await _parentService.getChildren();
      setState(() {
        _children = children;
        if (children.isNotEmpty && _selectedChild == null) {
          _selectedChild = children.first;
        }
      });

      // Load stats for selected child
      if (_selectedChild != null) {
        await _loadChildStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChildStats() async {
    if (_selectedChild == null) return;

    try {
      final attendanceStats = await _parentService.getChildAttendanceStats(_selectedChild!.uid);
      final feeSummary = await _parentService.getChildFeeSummary(_selectedChild!.uid);
      
      setState(() {
        _attendanceStats = attendanceStats;
        _feeSummary = feeSummary;
      });
    } catch (e) {
      // Silently fail - stats are not critical
      print('Error loading child stats: $e');
    }
  }

  Future<void> _selectChild() async {
    if (_children.isEmpty) return;

    if (_children.length == 1) {
      // Only one child, no need to show dialog
      return;
    }

    final selected = await showDialog<StudentModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Child'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _children.length,
            itemBuilder: (context, index) {
              final child = _children[index];
              return ListTile(
                title: Text(child.name),
                subtitle: Text('${child.className ?? 'N/A'} • Roll: ${child.rollNumber ?? 'N/A'}'),
                onTap: () => Navigator.pop(context, child),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedChild = selected);
      await _loadChildStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_children.isEmpty) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text("Parent Portal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.child_care_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No children linked to your account', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Please contact the school to link your children', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Logout"),
                          content: const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await _authService.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (c) => const RoleSelectionScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Logout",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBody: true,
      
      // --- 1. PREMIUM APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 75,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: kBackgroundColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05))),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: kPrimaryColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: kPrimaryColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Parent Portal", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
                Text(
                  _parent?.name ?? 'Parent',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Colors.white, 
              shape: BoxShape.circle, 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: StreamBuilder<int>(
              stream: _notificationService.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined, color: Colors.grey[800], size: 24),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const ParentNotificationsScreen()),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      // --- 2. SMOOTH BODY TRANSITION ---
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _getSelectedTab(),
        ),
      ),
      
      // --- 3. FLOATING GLASS NAVBAR ---
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: Colors.grey[400],
            backgroundColor: Colors.white,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Fees"),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Connect"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSelectedTab() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildFeesTab();
      case 2: return _buildChatTab();
      case 3: return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

  // ==================== TAB 1: HOME ====================
  Widget _buildHomeTab() {
    if (_selectedChild == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No child selected',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select a child to view their information',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final attendancePercentage = _attendanceStats?['percentage'] ?? 0.0;
    final totalDue = _feeSummary?['totalDue'] ?? 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Child Selector Pill
          Center(
            child: GestureDetector(
              onTap: _selectChild,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${_selectedChild!.name} (${_selectedChild!.className ?? 'N/A'})",
                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[800], fontSize: 13),
                    ),
                    if (_children.length > 1) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400], size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // 2. Key Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  "Attendance",
                  "${attendancePercentage.toStringAsFixed(0)}%",
                  "This Month",
                  Icons.calendar_today_rounded,
                  Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChildAttendanceScreen(child: _selectedChild!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildInfoCard(
                  "Fee Due",
                  "₹${totalDue.toStringAsFixed(0)}",
                  totalDue > 0 ? "Pay Now" : "All Paid",
                  Icons.account_balance_wallet_rounded,
                  totalDue > 0 ? Colors.orange : Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChildFeesScreen(child: _selectedChild!),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 3. Feature Grid
          Text("Student Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey[800])),
          const SizedBox(height: 15),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _buildFeatureIcon(
                "Attendance",
                Icons.calendar_today_rounded,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ChildAttendanceScreen(child: _selectedChild!)),
                ),
              ),
              _buildFeatureIcon(
                "Homework",
                Icons.menu_book_rounded,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ChildHomeworkScreen(child: _selectedChild!)),
                ),
              ),
              _buildFeatureIcon(
                "Results",
                Icons.bar_chart_rounded,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ChildResultsScreen(child: _selectedChild!)),
                ),
              ),
              _buildFeatureIcon(
                "Fees",
                Icons.account_balance_wallet_rounded,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ChildFeesScreen(child: _selectedChild!)),
                ),
              ),
              _buildFeatureIcon(
                "Behaviour",
                Icons.psychology_rounded,
                Colors.redAccent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ChildBehaviourScreen(child: _selectedChild!)),
                ),
              ),
              _buildFeatureIcon(
                "Notices",
                Icons.campaign_rounded,
                Colors.amber[800]!,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => NoticesScreen(classId: _selectedChild?.classId)),
                ),
              ),
              _buildFeatureIcon(
                "Events",
                Icons.event_note_rounded,
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => EventsScreen(classId: _selectedChild?.classId)),
                ),
              ),
              _buildFeatureIcon(
                "Transport",
                Icons.directions_bus_rounded,
                Colors.indigo,
                () => _openPlaceholder(context, "Transport", Icons.directions_bus),
              ),
              _buildFeatureIcon(
                "Leave",
                Icons.edit_calendar_rounded,
                Colors.pink,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => LeaveRequestScreen(child: _selectedChild),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== TAB 2: FEES ====================
  Widget _buildFeesTab() {
    if (_selectedChild == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No child selected',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select a child to view fee information',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ChildFeesScreen(child: _selectedChild!);
  }

  // ==================== TAB 3: CHAT ====================
  Widget _buildChatTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Connect", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey[900])),
        const SizedBox(height: 8),
        Text(
          "Get in touch with teachers, admin, or get instant help",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        
        // Class Teacher Contact
        if (_selectedChild != null)
          FutureBuilder<Map<String, String>?>(
            future: _parentService.getClassTeacherInfo(_selectedChild!.classId ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ));
              }
              
              if (snapshot.hasData && snapshot.data != null) {
                final teacher = snapshot.data!;
                final teacherName = teacher['teacherName'];
                if (teacherName != null && teacherName.isNotEmpty && teacherName != 'Unknown') {
                  return _buildChatCard(
                    "Class Teacher",
                    teacherName,
                    "Contact regarding ${_selectedChild!.name}",
                    Icons.person_rounded,
                    Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ClassTeacherContactScreen(child: _selectedChild!),
                      ),
                    ),
                  );
                }
              }
              
              return _buildChatCard(
                "Class Teacher",
                "Not Assigned",
                "Class teacher information not available",
                Icons.person_off_rounded,
                Colors.grey,
                isDisabled: true,
              );
            },
          ),
        
        if (_selectedChild != null) const SizedBox(height: 15),
        
        // Admin Office
        _buildChatCard(
          "Admin Office",
          "Helpdesk",
          "General inquiries and support",
          Icons.admin_panel_settings_rounded,
          Colors.blueGrey,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const AdminOfficeContactScreen(),
            ),
          ),
        ),
        
        const SizedBox(height: 15),
        
        // AI Assistant
        _buildChatCard(
          "AI Assistant",
          "24/7 Support",
          "Get instant answers to your questions",
          Icons.smart_toy_rounded,
          Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const ParentAIAssistantScreen(),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 4: PROFILE ====================
  Widget _buildProfileTab() {
    return const ParentProfileScreen();
  }

  // ==================== HELPER WIDGETS ====================

  void _openPlaceholder(BuildContext context, String title, IconData icon) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => PlaceholderScreen(title: title, icon: icon)));
  }

  Widget _buildInfoCard(String title, String val, String sub, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08), 
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(
    String title,
    String subtitle,
    String msg,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled ? Colors.grey[300]! : color.withOpacity(0.3),
            width: isDisabled ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey[100] : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDisabled ? Colors.grey[400] : color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled && onTap != null)
              Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }

}
