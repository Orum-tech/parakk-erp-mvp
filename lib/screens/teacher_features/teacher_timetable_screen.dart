import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/timetable_service.dart';
import '../../models/timetable_model.dart';
import '../../models/teacher_model.dart';
import '../../models/class_model.dart';

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _classId;
  String? _className;
  TeacherModel? _currentTeacher;
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isEditMode = false;
  int _viewMode = 0; // 0 = Class Timetable, 1 = My Schedule
  
  final List<DayOfWeek> _days = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
    DayOfWeek.saturday,
  ];

  @override
  void initState() {
    super.initState();
    _loadClassInfo();
  }

  Future<void> _loadClassInfo() async {
    setState(() => _isLoading = true);
    try {
      // Always load teacher data (needed for My Schedule view)
      final user = _auth.currentUser;
      if (user != null) {
        final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
        if (teacherDoc.exists) {
          setState(() {
            _currentTeacher = TeacherModel.fromDocument(teacherDoc);
          });
        }
      }

      // Check if teacher is class teacher
      final classId = await _timetableService.getClassTeacherClassId();
      
      if (classId == null) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      final hasPermission = await _timetableService.isClassTeacherForClass(classId);
      if (!hasPermission) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      // Parse className from classId
      final parts = classId.replaceFirst('class_', '').split('_');
      if (parts.length == 2) {
        setState(() {
          _classId = classId;
          _className = 'Class ${parts[0]}-${parts[1]}';
          _hasPermission = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("Timetable", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      initialIndex: _viewMode,
      length: 2, // Two main tabs: Class Timetable and My Schedule
      child: Builder(
        builder: (context) {
          final mainTabController = DefaultTabController.of(context);
          return Scaffold(
            backgroundColor: const Color(0xFFF0F4F4),
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Timetable", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text(
                    mainTabController.index == 0
                        ? (_className ?? 'Class Timetable')
                        : 'My Schedule',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                if (mainTabController.index == 0 && _hasPermission && _classId != null)
                  IconButton(
                    icon: Icon(_isEditMode ? Icons.check : Icons.edit),
                    onPressed: () {
                      setState(() => _isEditMode = !_isEditMode);
                    },
                    tooltip: _isEditMode ? 'Done Editing' : 'Edit Timetable',
                  ),
              ],
              bottom: TabBar(
                onTap: (index) {
                  setState(() {
                    _viewMode = index;
                    _isEditMode = false; // Disable edit mode when switching views
                  });
                },
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.teal,
                tabs: const [
                  Tab(text: 'Class Timetable', icon: Icon(Icons.class_, size: 18)),
                  Tab(text: 'My Schedule', icon: Icon(Icons.person, size: 18)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Tab 0: Class Timetable (only if class teacher)
                _buildClassTimetableView(),
                // Tab 1: My Schedule (all classes where teacher teaches)
                _buildMyScheduleView(),
              ],
            ),
            floatingActionButton: mainTabController.index == 0 && _isEditMode && _hasPermission && _classId != null
                ? FloatingActionButton(
                    onPressed: () {
                      // Default to Monday, user can change day in the dialog if needed
                      _showAddPeriodDialog(_days[0]);
                    },
                    backgroundColor: Colors.teal,
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          );
        },
      ),
    );
  }

  // Build Class Timetable View (for class teacher's class)
  Widget _buildClassTimetableView() {
    if (!_hasPermission || _classId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                'Only class teachers can view/edit timetable for their assigned class.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _days.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: _days.map((day) => Tab(text: _getDayAbbreviation(day))).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _days.map((day) => _buildDaySchedule(day)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Build My Schedule View (all classes where teacher teaches)
  Widget _buildMyScheduleView() {
    final user = _auth.currentUser;
    if (user == null || _currentTeacher == null) {
      return const Center(
        child: Text('Unable to load teacher information'),
      );
    }

    return DefaultTabController(
      length: _days.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: _days.map((day) => Tab(text: _getDayAbbreviation(day))).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _days.map((day) => _buildTeacherDaySchedule(day, user.uid)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Build schedule for a specific day showing all classes teacher teaches
  Widget _buildTeacherDaySchedule(DayOfWeek day, String teacherId) {
    return StreamBuilder<List<TimetableModel>>(
      stream: _timetableService.getTeacherTimetable(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allEntries = snapshot.data ?? [];
        final dayEntries = allEntries
            .where((entry) => entry.day == day && !entry.isBreak)
            .toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

        if (dayEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No classes scheduled for ${_getDayName(day)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...dayEntries.map((entry) => _buildTeacherPeriodCard(entry)),
          ],
        );
      },
    );
  }

  // Build period card for teacher's schedule (shows class info)
  Widget _buildTeacherPeriodCard(TimetableModel entry) {
    final timeStr = '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}';
    final color = _getSubjectColor(entry.subjectName);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.subjectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.class_, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 5),
                        Text(
                          entry.className,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Period ${entry.periodNumber}',
                  style: TextStyle(fontSize: 11, color: Colors.teal[700], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (entry.room != null) ...[
                const SizedBox(width: 15),
                const Icon(Icons.room, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(entry.room!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(DayOfWeek day) {
    if (_classId == null) return const Center(child: Text('No class selected'));

    return StreamBuilder<List<TimetableModel>>(
      stream: _timetableService.getClassTimetable(_classId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allEntries = snapshot.data ?? [];
        final dayEntries = allEntries
            .where((entry) => entry.day == day)
            .toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

        if (dayEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No schedule for ${_getDayName(day)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (_isEditMode) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPeriodDialog(day),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Period'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...dayEntries.map((entry) => _buildPeriodCard(entry)),
            if (_isEditMode && dayEntries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPeriodDialog(day),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Period'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodCard(TimetableModel entry) {
    final timeStr = '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}';
    final color = _getSubjectColor(entry.subjectName);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.isBreak ? entry.breakType ?? 'Break' : entry.subjectName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: entry.isBreak ? Colors.grey : Colors.black87,
                      ),
                    ),
                    if (entry.isBreak)
                      const SizedBox(width: 8),
                    if (entry.isBreak)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Period ${entry.periodNumber}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (entry.room != null) ...[
                      const SizedBox(width: 15),
                      const Icon(Icons.room, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(entry.room!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ],
                ),
                if (!entry.isBreak) ...[
                  const SizedBox(height: 5),
                  Text(
                    entry.teacherName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (_isEditMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.teal,
                  onPressed: () => _showEditPeriodDialog(entry),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  onPressed: () => _deletePeriod(entry),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String _getDayAbbreviation(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[subject.hashCode % colors.length];
  }

  Future<void> _showAddPeriodDialog(DayOfWeek day) async {
    await _showPeriodDialog(day: day);
  }

  Future<void> _showEditPeriodDialog(TimetableModel entry) async {
    await _showPeriodDialog(day: entry.day, entry: entry);
  }

  Future<void> _showPeriodDialog({required DayOfWeek day, TimetableModel? entry}) async {
    if (_classId == null || _className == null) return;

    final isEdit = entry != null;
    final formKey = GlobalKey<FormState>();
    
    // Form controllers
    String? selectedSubject = entry?.subjectName;
    String? selectedSubjectId = entry?.subjectId;
    String? selectedTeacherId = entry?.teacherId;
    String? selectedTeacherName = entry?.teacherName;
    int periodNumber = entry?.periodNumber ?? 1;
    TimeOfDay startTime = entry != null 
        ? TimeOfDay.fromDateTime(entry.startTime)
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = entry != null
        ? TimeOfDay.fromDateTime(entry.endTime)
        : const TimeOfDay(hour: 9, minute: 0);
    final roomController = TextEditingController(text: entry?.room ?? '');
    bool isBreak = entry?.isBreak ?? false;
    String? breakType = entry?.breakType;
    
    // Load teachers who teach this class
    List<Map<String, String>> teachersList = [];
    try {
      // First try with capitalized 'Teacher' role
      QuerySnapshot teachersSnapshot;
      try {
        // Query teachers who have this class in their classIds array
        teachersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'Teacher')
            .get();
      } catch (e) {
        // Fallback to lowercase 'teacher'
        teachersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get();
      }
      
      // Filter teachers who teach this class
      teachersList = teachersSnapshot.docs
          .map((doc) {
            try {
              final teacher = TeacherModel.fromDocument(doc);
              
              // Check if teacher teaches this class
              // Teacher teaches a class if:
              // 1. classIds array contains the classId, OR
              // 2. classTeacherClassId matches the classId
              final teachesThisClass = 
                  (teacher.classIds != null && teacher.classIds!.contains(_classId)) ||
                  (teacher.classTeacherClassId == _classId);
              
              if (teachesThisClass) {
                return <String, String>{
                  'id': doc.id,
                  'name': teacher.name,
                };
              }
              return null;
            } catch (e) {
              print('Error parsing teacher document: $e');
              return null;
            }
          })
          .where((teacher) => teacher != null)
          .cast<Map<String, String>>()
          .toList();
      
      // Sort by name
      teachersList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      if (teachersList.isEmpty) {
        print('WARNING: No teachers found for class $_classId');
        print('DEBUG: Checking all teachers...');
        // Debug: show all teachers for troubleshooting
        final allTeachers = teachersSnapshot.docs.map((doc) {
          try {
            final teacher = TeacherModel.fromDocument(doc);
            return '${teacher.name} - classIds: ${teacher.classIds}, classTeacherClassId: ${teacher.classTeacherClassId}';
          } catch (e) {
            return 'Error: $e';
          }
        }).toList();
        print('DEBUG: All teachers: $allTeachers');
      }
    } catch (e) {
      print('ERROR: Failed to load teachers: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load teachers: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Period' : 'Add Period'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day display (read-only)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Day: ${_getDayName(day)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Break toggle
                  Row(
                    children: [
                      Checkbox(
                        value: isBreak,
                        onChanged: (value) {
                          setDialogState(() {
                            isBreak = value ?? false;
                            if (!isBreak) {
                              breakType = null;
                            }
                          });
                        },
                      ),
                      const Text('This is a break period'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isBreak) ...[
                    // Break type
                    DropdownButtonFormField<String>(
                      initialValue: breakType,
                      decoration: const InputDecoration(
                        labelText: 'Break Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.coffee),
                      ),
                      items: ['Lunch', 'Short Break', 'Recess'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => breakType = value);
                      },
                      validator: (value) {
                        if (isBreak && (value == null || value.isEmpty)) {
                          return 'Please select break type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!isBreak) ...[
                    // Subject dropdown
                    if (_currentTeacher?.subjects != null && _currentTeacher!.subjects!.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Subject *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        items: _currentTeacher!.subjects!.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSubject = value;
                            selectedSubjectId = value; // Using subject name as ID for now
                          });
                        },
                        validator: (value) {
                          if (!isBreak && (value == null || value.isEmpty)) {
                            return 'Please select a subject';
                          }
                          return null;
                        },
                      ),
                    if (_currentTeacher?.subjects == null || _currentTeacher!.subjects!.isEmpty)
                      const Text('No subjects available. Please add subjects in your profile.'),
                    const SizedBox(height: 16),

                    // Teacher dropdown
                    if (teachersList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No teachers found for this class. Please ensure teachers are assigned to this class.',
                                style: TextStyle(color: Colors.orange[900], fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (teachersList.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Teacher *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: teachersList.map((teacher) {
                          return DropdownMenuItem(
                            value: teacher['id'],
                            child: Text(teacher['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTeacherId = value;
                            selectedTeacherName = teachersList
                                .firstWhere((t) => t['id'] == value)['name'];
                          });
                        },
                        validator: (value) {
                          if (!isBreak && (value == null || value.isEmpty)) {
                            return 'Please select a teacher';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Period number
                  TextFormField(
                    initialValue: periodNumber.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Period Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter period number';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return 'Please enter a valid period number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      periodNumber = int.tryParse(value ?? '1') ?? 1;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Start time
                  ListTile(
                    title: const Text('Start Time *'),
                    subtitle: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                  ),

                  // End time
                  ListTile(
                    title: const Text('End Time *'),
                    subtitle: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        setDialogState(() => endTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Room (optional)
                  TextFormField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.room),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();

                // Validate times
                final startDateTime = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  startTime.hour,
                  startTime.minute,
                );
                final endDateTime = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  endTime.hour,
                  endTime.minute,
                );

                if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End time must be after start time'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  if (isBreak) {
                    // Save break period
                    await _timetableService.createOrUpdateTimetableEntry(
                      timetableId: entry?.timetableId,
                      classId: _classId!,
                      className: _className!,
                      day: day,
                      periodNumber: periodNumber,
                      subjectId: 'break',
                      subjectName: breakType ?? 'Break',
                      teacherId: _auth.currentUser?.uid ?? '',
                      teacherName: _currentTeacher?.name ?? '',
                      startTime: startDateTime,
                      endTime: endDateTime,
                      room: roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                      isBreak: true,
                      breakType: breakType,
                    );
                  } else {
                    // Save regular period
                    if (selectedSubject == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a subject'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (teachersList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No teachers available for this class. Please assign teachers to this class first.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 4),
                        ),
                      );
                      return;
                    }
                    
                    if (selectedTeacherId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a teacher'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await _timetableService.createOrUpdateTimetableEntry(
                      timetableId: entry?.timetableId,
                      classId: _classId!,
                      className: _className!,
                      day: day,
                      periodNumber: periodNumber,
                      subjectId: selectedSubjectId ?? selectedSubject!,
                      subjectName: selectedSubject!,
                      teacherId: selectedTeacherId!,
                      teacherName: selectedTeacherName ?? '',
                      startTime: startDateTime,
                      endTime: endDateTime,
                      room: roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                      isBreak: false,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Period updated successfully' : 'Period added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePeriod(TimetableModel entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Period'),
        content: Text('Are you sure you want to delete ${entry.subjectName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _timetableService.deleteTimetableEntry(entry.timetableId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Period deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
