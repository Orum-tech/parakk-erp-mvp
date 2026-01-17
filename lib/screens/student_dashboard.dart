import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection_screen.dart'; // Logout logic
import '../models/student_model.dart';
import '../models/timetable_model.dart';
import '../services/timetable_service.dart';
import '../services/homework_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';

// ==========================================================
//                 1. IMPORTS: CORE SCREENS
// ==========================================================
import 'study_timer_screen.dart';
import 'homework_screen.dart';
import 'placeholder_screen.dart';

// ==========================================================
//                 2. IMPORTS: STUDENT FEATURES
// ==========================================================
import 'student_features/attendance_screen.dart';
import 'student_features/timetable_screen.dart';
import 'student_features/results_screen.dart';
import 'student_features/notes_screen.dart';
import 'student_features/notice_board_screen.dart';
import 'student_features/behaviour_screen.dart';
import 'student_features/library_screen.dart';
import 'student_features/bus_tracking_screen.dart';
import 'student_features/fees_screen.dart';
import 'student_features/events_screen.dart';
import 'student_features/analytics_screen.dart';
import 'student_features/support_screen.dart';

// ==========================================================
//                 3. IMPORTS: LEARNING HUB
// ==========================================================
import 'student_features/video_lessons_screen.dart';
import 'student_features/practice_tests_screen.dart';
import 'student_features/doubt_solver_screen.dart';
import 'student_features/saved_resources_screen.dart';
import 'student_features/ai_tutor_screen.dart';

// ==========================================================
//                 4. IMPORTS: CONNECT (TEACHER CHAT)
// ==========================================================
import 'student_features/teacher_chat_screen.dart';
import 'student_features/student_admin_contact_screen.dart';

// ==========================================================
//                 5. IMPORTS: PROFILE
// ==========================================================
import 'student_features/my_account_screen.dart';
import 'student_features/academic_reports_screen.dart';
import 'student_features/app_settings_screen.dart';
import 'student_features/help_center_screen.dart';
import 'student_features/notifications_screen.dart';
import '../services/notification_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  // Premium Student Color Palette
  final Color kPrimaryColor = const Color(0xFF2563EB); // Electric Blue
  final Color kSecondaryColor = const Color(0xFF3B82F6); // Soft Blue
  final Color kBackgroundColor = const Color(0xFFF8FAFC); // Slate 50 (Very Light Grey)
  final Color kCardColor = Colors.white;

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final TimetableService _timetableService = TimetableService();
  final HomeworkService _homeworkService = HomeworkService();
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  final StudentService _studentService = StudentService();

  // Data state
  StudentModel? _student;
  TimetableModel? _nextClass;
  int _pendingHomeworkCount = 0;
  Map<String, dynamic>? _attendanceStats;
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

      // Load student data
      final studentDoc = await _firestore.collection('users').doc(user.uid).get();
      if (studentDoc.exists) {
        setState(() {
          _student = StudentModel.fromDocument(studentDoc);
        });
      }

      // Load next class
      if (_student?.classId != null) {
        await _loadNextClass();
        await _loadHomeworkCount();
        await _loadAttendanceStats();
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNextClass() async {
    if (_student?.classId == null) return;
    try {
      final now = DateTime.now();
      final currentDay = _getDayOfWeek(now.weekday);
      final currentDateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      // Get class timetable
      final timetable = await _timetableService.getClassTimetable(_student!.classId!).first;
      
      // Find next class today or in the next 7 days
      TimetableModel? nextClass;
      DateTime? nextClassDateTime;

      // Check today's remaining classes
      for (var entry in timetable) {
        if (entry.day == currentDay && !entry.isBreak) {
          final entryDateTime = DateTime(
            now.year, 
            now.month, 
            now.day, 
            entry.startTime.hour, 
            entry.startTime.minute
          );
          
          if (entryDateTime.isAfter(currentDateTime)) {
            if (nextClassDateTime == null || entryDateTime.isBefore(nextClassDateTime)) {
              nextClass = entry;
              nextClassDateTime = entryDateTime;
            }
          }
        }
      }

      // If no class today, check next 7 days
      if (nextClass == null) {
        for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
          final checkDate = now.add(Duration(days: dayOffset));
          final checkDay = _getDayOfWeek(checkDate.weekday);
          
          for (var entry in timetable) {
            if (entry.day == checkDay && !entry.isBreak) {
              final entryDateTime = DateTime(
                checkDate.year, 
                checkDate.month, 
                checkDate.day, 
                entry.startTime.hour, 
                entry.startTime.minute
              );
              
              if (nextClassDateTime == null || entryDateTime.isBefore(nextClassDateTime)) {
                nextClass = entry;
                nextClassDateTime = entryDateTime;
              }
            }
          }
          
          if (nextClass != null) break;
        }
      }

      setState(() {
        _nextClass = nextClass;
      });
    } catch (e) {
      debugPrint('Error loading next class: $e');
    }
  }

  DayOfWeek _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return DayOfWeek.monday;
      case 2: return DayOfWeek.tuesday;
      case 3: return DayOfWeek.wednesday;
      case 4: return DayOfWeek.thursday;
      case 5: return DayOfWeek.friday;
      case 6: return DayOfWeek.saturday;
      case 7: return DayOfWeek.sunday;
      default: return DayOfWeek.monday;
    }
  }

  Future<void> _loadHomeworkCount() async {
    if (_student?.classId == null) return;
    try {
      final homework = await _homeworkService.getStudentHomework(_student!.classId!).first;
      final now = DateTime.now();
      
      // Count pending homework (not submitted and due date in future)
      final pending = homework.where((hw) {
        return hw.dueDate.isAfter(now);
      }).length;
      
      setState(() {
        _pendingHomeworkCount = pending;
      });
    } catch (e) {
      debugPrint('Error loading homework count: $e');
    }
  }

  Future<void> _loadAttendanceStats() async {
    if (_student?.uid == null) return;
    try {
      final stats = await _attendanceService.getStudentAttendanceStats(_student!.uid);
      setState(() {
        _attendanceStats = stats;
      });
    } catch (e) {
      debugPrint('Error loading attendance stats: $e');
    }
  }

  String _formatTimeUntil(DateTime targetTime) {
    final now = DateTime.now();
    final targetDateTime = DateTime(
      targetTime.year,
      targetTime.month,
      targetTime.day,
      targetTime.hour,
      targetTime.minute,
    );
    final currentDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    
    final difference = targetDateTime.difference(currentDateTime);
    
    if (difference.isNegative) {
      return 'Started';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    }
    
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    }
    
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''}';
    }
    
    return 'Starting soon';
  }

  String _getClassName() {
    if (_student?.className != null && _student?.section != null) {
      return '${_student!.className}-${_student!.section}';
    } else if (_student?.classId != null) {
      final parts = _student!.classId!.replaceFirst('class_', '').split('_');
      if (parts.length == 2) {
        return 'Class ${parts[0]}-${parts[1]}';
      }
    }
    return 'Class';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBody: true, // Navbar floats over content

      // --------------------------------------------------------
      //                       APP BAR
      // --------------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: kBackgroundColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.05)),
            ),
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
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500
                  ),
                ),
                Text(
                  _student?.name ?? 'Student',
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
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10
                )
              ],
            ),
            child: StreamBuilder<int>(
              stream: _notificationService.getUnreadCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined, color: Colors.grey[800], size: 24),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen())),
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

      // --------------------------------------------------------
      //                       BODY
      // --------------------------------------------------------
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _getSelectedTab(),
        ),
      ),

      // --------------------------------------------------------
      //                  BOTTOM NAVIGATION BAR
      // --------------------------------------------------------
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10)
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2)
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: Colors.grey[400],
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                label: "Dashboard"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_rounded),
                label: "Learn"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_rounded),
                label: "Connect"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: "Profile"
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSelectedTab() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildLearningTab();
      case 2: return _buildChatTab();
      case 3: return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

  // ==========================================================
  //                  TAB 1: HOME DASHBOARD
  // ==========================================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- 1. NEXT CLASS ALERT ---
          if (_nextClass != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border(left: BorderSide(color: kPrimaryColor, width: 5)),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15)
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "UPCOMING CLASS",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2
                          )
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_nextClass!.subjectName} (${_nextClass!.className})",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black87
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_formatTimeUntil(_nextClass!.startTime)}${_nextClass!.room != null ? ' • Room ${_nextClass!.room}' : ''}",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600
                          )
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.08),
                      shape: BoxShape.circle
                    ),
                    child: Icon(Icons.videocam_rounded, size: 22, color: kPrimaryColor),
                  )
                ],
              ),
            )
          else if (_student?.classId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border(left: BorderSide(color: Colors.grey[300]!, width: 5)),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15)
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NO UPCOMING CLASS",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2
                          )
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "No classes scheduled",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.grey[600]
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 25),

          // --- 2. FOCUS MODE CARD (HERO) ---
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudyTimerScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [kPrimaryColor, const Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10)
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: const Text(
                            "🔥 Focus Mode",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Ready to Study?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900
                          )
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Track your productivity today.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13
                          )
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10
                        )
                      ]
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: kPrimaryColor, size: 32),
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),

          // --- 3. QUICK ACTIONS ---
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800]
            )
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildQuickAction(
                  "Homework", "$_pendingHomeworkCount Due", Icons.edit_document, Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HomeworkScreen()))
                ),
                _buildQuickAction(
                  "Timetable", "View", Icons.calendar_month_rounded, Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TimetableScreen()))
                ),
                _buildQuickAction(
                  "Results", "New!", Icons.bar_chart_rounded, Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ResultsScreen()))
                ),
                _buildQuickAction(
                  "Notices", "Updates", Icons.campaign_rounded, Colors.redAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NoticeBoardScreen()))
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 4. STUDENT HUB GRID ---
          Text(
            "Student Hub",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800]
            )
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _buildGridTile(
                "Attendance", Icons.fact_check_rounded, Colors.green,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AttendanceScreen()))
              ),
              _buildGridTile(
                "Notes", Icons.menu_book_rounded, Colors.indigo,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotesScreen()))
              ),
              _buildGridTile(
                "Behaviour", Icons.psychology_rounded, Colors.red,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BehaviourScreen()))
              ),
              _buildGridTile(
                "Library", Icons.local_library_rounded, Colors.brown,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LibraryScreen()))
              ),
              _buildGridTile(
                "Bus Track", Icons.directions_bus_rounded, Colors.blueGrey,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BusTrackingScreen()))
              ),
              _buildGridTile(
                "Pay Fees", Icons.payment_rounded, Colors.deepPurple,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FeesScreen()))
              ),
              _buildGridTile(
                "Events", Icons.emoji_events_rounded, Colors.pink,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EventsScreen()))
              ),
              _buildGridTile(
                "Analytics", Icons.pie_chart_rounded, Colors.deepOrange,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AnalyticsScreen()))
              ),
              _buildGridTile(
                "Support", Icons.headset_mic_rounded, Colors.cyan,
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SupportScreen()))
              ),
            ],
          ),
          
          const SizedBox(height: 100),
        ],
      ),
      ),
    );
  }

  // ==========================================================
  //                  TAB 2: LEARNING HUB
  // ==========================================================
  Widget _buildLearningTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Learning Hub",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)
        ),
        const SizedBox(height: 5),
        Text(
          "Access your study materials",
          style: TextStyle(fontSize: 14, color: Colors.grey[600])
        ),
        const SizedBox(height: 25),

        _buildWideCard(
          "Video Lessons", "Watch recorded lectures", Icons.play_circle_filled_rounded, Colors.redAccent,
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const VideoLessonsScreen()))
        ),
        _buildWideCard(
          "Practice Tests", "Mock exams & quizzes", Icons.quiz_rounded, Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PracticeTestsScreen()))
        ),
        _buildWideCard(
          "AI Doubt Solver", "Instant homework help", Icons.auto_awesome, Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DoubtSolverScreen()))
        ),
        _buildWideCard(
          "Saved Resources", "Offline notes & PDFs", Icons.bookmark_rounded, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SavedResourcesScreen()))
        ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  // ==========================================================
  //                  TAB 3: CHAT & CONNECT
  // ==========================================================
  Widget _buildChatTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Smart Connect",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)
          ),
          const SizedBox(height: 5),
          Text(
            "Get in touch with teachers, admin, or get instant help",
            style: TextStyle(fontSize: 13, color: Colors.grey[600])
          ),
          const SizedBox(height: 20),
          
          // --- AI TUTOR CARD ---
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AITutorScreen())),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo.shade800]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ask AI Tutor",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "24/7 Academic Assistance",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.indigo, size: 20),
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // --- TALK TO TEACHERS CARD ---
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherChatScreen())),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.05), blurRadius: 15)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.people_alt_rounded, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Talk to Teachers", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Ask questions directly", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- ADMIN OFFICE CARD ---
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudentAdminContactScreen())),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.05), blurRadius: 15)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.blueGrey, size: 28),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Admin Office", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("General inquiries and support", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Class Teacher Quick Access
          if (_student?.classId != null)
            FutureBuilder<Map<String, String>?>(
              future: _studentService.getClassTeacher(_student!.classId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  final teacher = snapshot.data!;
                  final teacherName = teacher['teacherName'];
                  
                  if (teacherName != null && teacherName.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Quick Access", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 15),
                        _buildMessageTile(
                          "Class Teacher",
                          teacherName,
                          "Contact your class teacher",
                          Icons.person_rounded,
                          Colors.green,
                          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TeacherChatScreen())),
                        ),
                        const SizedBox(height: 15),
                        _buildMessageTile(
                          "Notices",
                          "School Announcements",
                          "View important notices",
                          Icons.campaign_rounded,
                          Colors.orange,
                          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NoticeBoardScreen())),
                        ),
                      ],
                    );
                  }
                }
                
                return const SizedBox.shrink();
              },
            ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==========================================================
  //                  TAB 4: PROFILE SETTINGS
  // ==========================================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryColor.withOpacity(0.1), width: 3)
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: kPrimaryColor)
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _student?.name ?? 'Student',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)
                ),
                Text(
                  "${_getClassName()}${_student?.rollNumber != null ? ' • Roll No. ${_student!.rollNumber}' : ''}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          _buildSettingsTile(
            "My Account", Icons.person_outline_rounded, Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MyAccountScreen()))
          ),
          _buildSettingsTile(
            "Academic Reports", Icons.analytics_outlined, Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AcademicReportsScreen()))
          ),
          _buildSettingsTile(
            "App Settings", Icons.settings_outlined, Colors.grey,
            () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AppSettingsScreen()))
          ),
          _buildSettingsTile(
            "Help Center", Icons.help_outline_rounded, Colors.teal,
            () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HelpCenterScreen()))
          ),
          
          const SizedBox(height: 20),
          _buildSettingsTile(
            "Logout", Icons.logout_rounded, Colors.red,
            () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _authService.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (c) => const RoleSelectionScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
            isDestructive: true
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==========================================================
  //                  HELPER WIDGETS
  // ==========================================================

  void _openPlaceholder(BuildContext context, String title, IconData icon) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title, icon: icon)));
  }

  Widget _buildQuickAction(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // Slightly wider
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
          ],
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
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(String title, String subtitle, String msg, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDestructive ? Colors.red[50] : color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: isDestructive ? Colors.red : color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDestructive ? Colors.red : Colors.black87)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
      ),
    );
  }
}