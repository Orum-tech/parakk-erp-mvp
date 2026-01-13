import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'placeholder_screen.dart'; // Ensure this file exists
import 'login_screen.dart'; // Ensure this file exists
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import '../models/timetable_model.dart';
import '../models/homework_model.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/timetable_service.dart';
import '../services/homework_service.dart';
import '../services/marks_service.dart';
import '../services/auth_service.dart';

// ==========================================================
//                 1. IMPORTS: PROFILE & SETTINGS
// ==========================================================
import 'teacher_features/edit_profile_screen.dart';
import 'teacher_features/class_settings_screen.dart';
import 'teacher_features/help_support_screen.dart';

// ==========================================================
//                 2. IMPORTS: CHAT & NOTICES
// ==========================================================
import 'teacher_features/school_notices_screen.dart';
import 'teacher_features/parent_chat_screen.dart';

// ==========================================================
//                 3. IMPORTS: QUICK ACTIONS
// ==========================================================
import 'teacher_features/attendance_screen.dart';
import 'teacher_features/homework_screen.dart'; // ✅ FIXED: Importing the correct Homework Screen
import 'teacher_features/marks_entry_screen.dart';
import 'teacher_features/teacher_timetable_screen.dart';

// ==========================================================
//                 4. IMPORTS: CLASS MANAGEMENT
// ==========================================================
import 'teacher_features/upload_notes_screen.dart';
import 'teacher_features/behaviour_log_screen.dart';
import 'teacher_features/class_analytics_screen.dart';
import 'teacher_features/syllabus_tracker_screen.dart';
import 'teacher_features/class_reports_screen.dart';

// ==========================================================
//                 5. IMPORTS: MY CLASS HUB
// ==========================================================
import 'teacher_features/student_directory_screen.dart';
import 'teacher_features/attendance_history_screen.dart';
import 'teacher_features/leave_requests_screen.dart';
import 'teacher_features/incident_log_screen.dart';
import 'teacher_features/lesson_plan_screen.dart';

// ==========================================================
//          6. IMPORTS: STUDY HUB (Shared with Student)
// ==========================================================
import 'student_features/video_lessons_screen.dart';
import 'student_features/practice_tests_screen.dart';
import 'student_features/doubt_solver_screen.dart';
import 'student_features/saved_resources_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  // Professional Corporate Color Palette
  final Color kPrimaryColor = const Color(0xFF0F766E); // Deep Teal
  final Color kSecondaryColor = const Color(0xFF14B8A6); // Bright Teal
  final Color kBackgroundColor = const Color(0xFFF8FAFC); // Very Light Blue-Grey
  final Color kCardColor = Colors.white;

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();
  final TimetableService _timetableService = TimetableService();
  final HomeworkService _homeworkService = HomeworkService();
  final MarksService _marksService = MarksService();
  final AuthService _authService = AuthService();

  // Data state
  TeacherModel? _teacher;
  String? _classTeacherClassId;
  String? _classTeacherClassName;
  int _totalStudents = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  TimetableModel? _nextClass;
  int _homeworkCount = 0;
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

      // Load teacher data
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        setState(() {
          _teacher = TeacherModel.fromDocument(teacherDoc);
        });
      }

      // Load class teacher class info
      if (_teacher?.classTeacherClassId != null) {
        _classTeacherClassId = _teacher!.classTeacherClassId;
        
        // Parse class name
        final parts = _classTeacherClassId!.replaceFirst('class_', '').split('_');
        if (parts.length == 2) {
          _classTeacherClassName = 'Class ${parts[0]}-${parts[1]}';
        }

        // Load student count
        await _loadStudentCount();
        
        // Load today's attendance
        await _loadTodayAttendance();
      }

      // Load next class
      await _loadNextClass();

      // Load homework count
      await _loadHomeworkCount();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentCount() async {
    if (_classTeacherClassId == null) return;
    try {
      final students = await _attendanceService.getStudentsByClass(_classTeacherClassId!);
      setState(() {
        _totalStudents = students.length;
      });
    } catch (e) {
      debugPrint('Error loading student count: $e');
    }
  }

  Future<void> _loadTodayAttendance() async {
    if (_classTeacherClassId == null) return;
    try {
      final today = DateTime.now();
      final attendance = await _attendanceService.getAttendanceByDateAndClass(
        classId: _classTeacherClassId!,
        date: today,
      ).first;

      int present = 0;
      int absent = 0;
      int late = 0;

      for (var record in attendance) {
        switch (record.status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
          default:
            break;
        }
      }

      setState(() {
        _presentCount = present;
        _absentCount = absent;
        _lateCount = late;
      });
    } catch (e) {
      debugPrint('Error loading today attendance: $e');
    }
  }

  Future<void> _loadNextClass() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final currentDay = _getDayOfWeek(now.weekday);
      final currentDateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);

      // Get teacher's timetable
      final timetable = await _timetableService.getTeacherTimetable(user.uid).first;
      
      // Find next class today or in the next 7 days
      TimetableModel? nextClass;
      DateTime? nextClassDateTime;

      // Check today's remaining classes
      for (var entry in timetable) {
        if (entry.day == currentDay && !entry.isBreak) {
          // Create a DateTime for today with the entry's start time
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
    try {
      final homework = await _homeworkService.getTeacherHomework().first;
      setState(() {
        _homeworkCount = homework.length;
      });
    } catch (e) {
      debugPrint('Error loading homework count: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatTimeUntil(DateTime targetTime) {
    final now = DateTime.now();
    // Create a proper DateTime for comparison
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
      extendBody: true, // Allows content to flow behind the bottom navbar

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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_getGreeting()},", 
                  style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 12, 
                    fontWeight: FontWeight.w500
                  )
                ),
                Text(
                  _teacher?.name ?? 'Teacher', 
                  style: const TextStyle(
                    color: Colors.black87, 
                    fontWeight: FontWeight.w800, 
                    fontSize: 18
                  )
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
            child: IconButton(
              onPressed: () => _openPlaceholder(context, "Notifications", Icons.notifications),
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[800], size: 24),
            ),
          ),
        ],
      ),

      // --------------------------------------------------------
      //                       MAIN BODY
      // --------------------------------------------------------
      body: _buildBody(),

      // --------------------------------------------------------
      //                FLOATING ACTION BUTTON
      // --------------------------------------------------------
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showQuickActionMenu(context),
              backgroundColor: kPrimaryColor,
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,

      // --------------------------------------------------------
      //                 BOTTOM NAVIGATION BAR
      // --------------------------------------------------------
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), 
              blurRadius: 20, 
              offset: const Offset(0, 5)
            )
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
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded, size: 26), 
                label: "Home"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded, size: 26), 
                label: "Class"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 26), 
                label: "Chat"
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 26), 
                label: "Profile"
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle Tab Switching Animation
  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _getSelectedTab(),
      ),
    );
  }

  // Return the widget corresponding to the selected tab
  Widget _getSelectedTab() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildMyClassTab();
      case 2: return _buildMessagesTab();
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: Colors.amber[700]!, width: 4)),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)
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
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_nextClass!.subjectName} (${_nextClass!.className})", 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16
                          )
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${_nextClass!.room != null ? 'Room ${_nextClass!.room} • ' : ''}${_formatTimeUntil(_nextClass!.startTime)}", 
                          style: TextStyle(
                            color: Colors.grey[600], 
                            fontSize: 12
                          )
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber[50], 
                      shape: BoxShape.circle
                    ),
                    child: Icon(Icons.access_time_filled, color: Colors.amber[800], size: 20),
                  )
                ],
              ),
            )
          else if (_teacher?.classIds != null && _teacher!.classIds!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: Colors.grey[300]!, width: 4)),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)
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
                            fontWeight: FontWeight.bold, 
                            letterSpacing: 1
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "No classes scheduled", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
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

          // --- 2. STATS CARD (HERO SECTION) ---
          if (_classTeacherClassName != null)
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [kPrimaryColor, const Color(0xFF0D9488)]
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.4), 
                    blurRadius: 20, 
                    offset: const Offset(0, 10)
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _classTeacherClassName!, 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 24, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                          const Text(
                            "Class Teacher", 
                            style: TextStyle(
                              color: Colors.white70, 
                              fontSize: 13
                            )
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), 
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Icon(Icons.groups, color: Colors.white, size: 28),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn(_totalStudents.toString(), "Total", Colors.white),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildStatColumn(_presentCount.toString(), "Present", Colors.greenAccent),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildStatColumn(_absentCount.toString(), "Absent", Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 30),

          // --- 3. QUICK ACTIONS ROW ---
          Text(
            "Quick Actions", 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w700, 
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
                _buildActionCard(
                  "Attendance", 
                  Icons.check_circle_outline, 
                  Colors.blue, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AttendanceScreen()))
                ),
                // ✅ UPDATED: Navigates to HomeworkScreen
                _buildActionCard(
                  "Homework", 
                  Icons.assignment_outlined, 
                  Colors.orange, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HomeworkScreen()))
                ),
                _buildActionCard(
                  "Timetable", 
                  Icons.calendar_today_outlined, 
                  Colors.purple, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TeacherTimetableScreen()))
                ),
                _buildActionCard(
                  "Marks", 
                  Icons.grading_outlined, 
                  Colors.pink, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarksEntryScreen()))
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 4. MANAGEMENT CONSOLE (GRID) ---
          Text(
            "Management Console", 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w700, 
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
                "Upload\nNotes", 
                Icons.cloud_upload_rounded, 
                Colors.indigo, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const UploadNotesScreen()))
              ),
              _buildGridTile(
                "Behaviour\nLog", 
                Icons.psychology_rounded, 
                Colors.teal, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BehaviourLogScreen()))
              ),
              _buildGridTile(
                "Parent\nChat", 
                Icons.chat_bubble_rounded, 
                Colors.deepOrange, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ParentChatScreen()))
              ),
              _buildGridTile(
                "Analytics", 
                Icons.pie_chart_rounded, 
                Colors.blueGrey, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ClassAnalyticsScreen()))
              ),
              _buildGridTile(
                "Syllabus", 
                Icons.menu_book_rounded, 
                Colors.brown, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SyllabusTrackerScreen()))
              ),
              _buildGridTile(
                "Reports", 
                Icons.description_rounded, 
                Colors.redAccent, 
                () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ClassReportsScreen()))
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- 5. STUDY HUB ACCESS (GRID) ---
          Text(
            "Study Hub Access", 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w700, 
              color: Colors.grey[800]
            )
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5, // Wide buttons
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
               _buildWideGridTile(
                 "Video Lessons", 
                 Icons.play_circle_fill_rounded, 
                 Colors.redAccent, 
                 () => Navigator.push(context, MaterialPageRoute(builder: (c) => const VideoLessonsScreen()))
               ),
               _buildWideGridTile(
                 "Practice Tests", 
                 Icons.quiz_rounded, 
                 Colors.green, 
                 () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PracticeTestsScreen()))
               ),
               _buildWideGridTile(
                 "Doubt Solver", 
                 Icons.live_help_rounded, 
                 Colors.orange, 
                 () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DoubtSolverScreen()))
               ),
               _buildWideGridTile(
                 "Resources", 
                 Icons.bookmark_rounded, 
                 Colors.teal, 
                 () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SavedResourcesScreen()))
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
  //                  TAB 2: MY CLASS HUB
  // ==========================================================
  Widget _buildMyClassTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Class Directory", 
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 20),
        
        _buildListTile(
          "Student Directory", 
          "View details of $_totalStudents students", 
          Icons.folder_shared_outlined, 
          Colors.blue, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudentDirectoryScreen()))
        ),
        _buildListTile(
          "Attendance History", 
          "View monthly logs", 
          Icons.history_edu, 
          Colors.orange, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AttendanceHistoryScreen()))
        ),
        _buildListTile(
          "Leave Requests", 
          "2 Pending approvals", 
          Icons.mail_outline, 
          Colors.purple, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaveRequestsScreen()))
        ),
        _buildListTile(
          "Lesson Planner", 
          "Track syllabus progress", 
          Icons.edit_note, 
          Colors.teal, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LessonPlanScreen()))
        ),
        _buildListTile(
          "Incident Reports", 
          "Disciplinary logs", 
          Icons.warning_amber_rounded, 
          Colors.red, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const IncidentLogScreen()))
        ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  // ==========================================================
  //                  TAB 3: COMMUNICATIONS
  // ==========================================================
  Widget _buildMessagesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Communications", 
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 20),
        
        _buildBigCard(
          "School Notices", 
          "Broadcast announcements to class", 
          Icons.campaign, 
          Colors.blue[800]!, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SchoolNoticesScreen()))
        ),
        
        const SizedBox(height: 15),
        
        _buildBigCard(
          "Parent Messages", 
          "Direct chat with guardians", 
          Icons.forum, 
          Colors.green[700]!, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ParentChatScreen()))
        ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  // ==========================================================
  //                  TAB 4: PROFILE SETTINGS
  // ==========================================================
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05), 
                blurRadius: 15
              )
            ]
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35, 
                backgroundColor: kPrimaryColor.withOpacity(0.1), 
                child: Icon(Icons.person, size: 35, color: kPrimaryColor)
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    _teacher?.name ?? 'Teacher', 
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    )
                  ), 
                  Text(
                    _teacher?.employeeId != null ? "ID: ${_teacher!.employeeId}" : "Teacher", 
                    style: const TextStyle(
                      color: Colors.grey
                    )
                  )
                ]
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        _buildProfileOption(
          "Edit Profile", 
          Icons.edit_outlined, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EditProfileScreen()))
        ),
        _buildProfileOption(
          "Class Settings", 
          Icons.settings_outlined, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ClassSettingsScreen()))
        ),
        _buildProfileOption(
          "Help & Support", 
          Icons.help_outline, 
          () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HelpSupportScreen()))
        ),
        
        const SizedBox(height: 20),
        
        _buildProfileOption(
          "Logout", 
          Icons.logout, 
          () async {
            await _authService.logout();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginScreen(userRole: 'Teacher')),
                (route) => false,
              );
            }
          }, 
          isDestructive: true
        ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  // ==========================================================
  //                  HELPER WIDGETS
  // ==========================================================

  Widget _buildStatColumn(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val, 
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: color
          )
        ),
        Text(
          label, 
          style: const TextStyle(
            fontSize: 12, 
            color: Colors.white70
          )
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                shape: BoxShape.circle
              ), 
              child: Icon(icon, color: color, size: 22)
            ),
            const SizedBox(height: 10),
            Text(
              title, 
              style: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600
              )
            ),
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
            BoxShadow(
              color: Colors.grey.withOpacity(0.05), 
              blurRadius: 5
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(
                color: color.withOpacity(0.05), 
                shape: BoxShape.circle
              ), 
              child: Icon(icon, color: color, size: 28)
            ),
            const SizedBox(height: 10),
            Text(
              title, 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w600, 
                color: Colors.grey[800]
              )
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWideGridTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05), 
              blurRadius: 5
            )
          ], 
          border: Border.all(color: Colors.grey.withOpacity(0.05))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              title, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600, 
                color: Colors.grey[800]
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03), 
            blurRadius: 5
          )
        ]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8), 
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(8)
          ), 
          child: Icon(icon, color: color, size: 20)
        ),
        title: Text(
          title, 
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 15
          )
        ),
        subtitle: Text(
          subtitle, 
          style: const TextStyle(
            fontSize: 12, 
            color: Colors.grey
          )
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBigCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.grey.withOpacity(0.1))
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(10)
              ), 
              child: Icon(icon, color: color, size: 28)
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  title, 
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  )
                ), 
                Text(
                  subtitle, 
                  style: const TextStyle(
                    color: Colors.grey, 
                    fontSize: 12
                  )
                )
              ]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red[50] : Colors.grey[100], 
          borderRadius: BorderRadius.circular(8)
        ), 
        child: Icon(
          icon, 
          color: isDestructive ? Colors.red : Colors.grey[700], 
          size: 20
        )
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w600, 
          color: isDestructive ? Colors.red : Colors.black87
        )
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New", 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.campaign), 
              title: const Text("Announcement"), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (c) => const SchoolNoticesScreen())); 
              }
            ),
            // ✅ UPDATED: Navigates to HomeworkScreen
            ListTile(
              leading: const Icon(Icons.post_add), 
              title: const Text("Homework"), 
              onTap: () { 
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (c) => const HomeworkScreen())); 
              }
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaceholder(BuildContext context, String title, IconData icon) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title, icon: icon))
    );
  }
}