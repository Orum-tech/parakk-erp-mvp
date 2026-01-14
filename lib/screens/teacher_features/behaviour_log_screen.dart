import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/behaviour_log_service.dart';
import '../../models/behaviour_log_model.dart';
import '../../models/student_model.dart';
import '../../models/teacher_model.dart';

class BehaviourLogScreen extends StatefulWidget {
  const BehaviourLogScreen({super.key});

  @override
  State<BehaviourLogScreen> createState() => _BehaviourLogScreenState();
}

class _BehaviourLogScreenState extends State<BehaviourLogScreen> {
  final BehaviourLogService _behaviourLogService = BehaviourLogService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _classId;
  String? _className;
  List<StudentModel> _students = [];
  List<BehaviourLogModel> _recentLogs = [];
  bool _isLoading = false;
  bool _isLoadingStudents = true;
  bool _hasPermission = false;
  TeacherModel? _teacher;

  @override
  void initState() {
    super.initState();
    _loadClassAndStudents();
  }

  Future<void> _loadClassAndStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      // Load teacher data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
        if (teacherDoc.exists) {
          setState(() {
            _teacher = TeacherModel.fromDocument(teacherDoc);
          });
        }
      }

      // Get class teacher's class
      final classId = await _behaviourLogService.getClassTeacherClassId();
      
      if (classId == null) {
        setState(() {
          _hasPermission = false;
          _isLoadingStudents = false;
        });
        return;
      }

      // Verify permission
      final hasPermission = await _behaviourLogService.isClassTeacherForClass(classId);
      if (!hasPermission) {
        setState(() {
          _hasPermission = false;
          _isLoadingStudents = false;
        });
        return;
      }

      setState(() {
        _classId = classId;
        _hasPermission = true;
      });

      // Parse className from classId
      final className = await _behaviourLogService.getClassName(classId);
      setState(() {
        _className = className;
      });

      // Load students
      final students = await _behaviourLogService.getStudentsByClass(classId);
      
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });

      // Load recent logs
      _loadRecentLogs();
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadRecentLogs() async {
    if (_classId == null) return;
    try {
      final logs = await _behaviourLogService
          .getClassBehaviourLogs(_classId!)
          .first;
      setState(() {
        _recentLogs = logs.take(10).toList(); // Show last 10 logs
      });
    } catch (e) {
      debugPrint('Error loading recent logs: $e');
    }
  }

  void _addLog(StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddLogBottomSheet(
        student: student,
        classId: _classId!,
        className: _className!,
        teacher: _teacher!,
        onLogAdded: () {
          _loadRecentLogs();
        },
      ),
    );
  }

  Color _getBehaviourColor(BehaviourType type) {
    switch (type) {
      case BehaviourType.positive:
        return Colors.green;
      case BehaviourType.negative:
        return Colors.red;
      case BehaviourType.appreciation:
        return Colors.blue;
      case BehaviourType.neutral:
        return Colors.orange;
    }
  }

  IconData _getBehaviourIcon(BehaviourType type) {
    switch (type) {
      case BehaviourType.positive:
        return Icons.thumb_up;
      case BehaviourType.negative:
        return Icons.thumb_down;
      case BehaviourType.appreciation:
        return Icons.star;
      case BehaviourType.neutral:
        return Icons.chat_bubble;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStudents) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Behaviour Monitor", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Behaviour Monitor", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only class teachers can log behavior for their assigned class.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text("Behaviour Monitor - $_className", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadClassAndStudents();
        },
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            // Recent Logs Section
            if (_recentLogs.isNotEmpty) ...[
              const Text(
                "Recent Logs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              ..._recentLogs.map((log) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getBehaviourColor(log.behaviourType).withOpacity(0.1),
                    child: Icon(
                      _getBehaviourIcon(log.behaviourType),
                      color: _getBehaviourColor(log.behaviourType),
                    ),
                  ),
                  title: Text(
                    log.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        log.remark,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.behaviourTypeString} • ${_formatDate(log.date)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
            ],
            // Students List
            const Text(
              "Students",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            if (_students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No students found in this class.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._students.asMap().entries.map((entry) {
                final index = entry.key;
                final student = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[50],
                      child: Text(
                        student.rollNumber ?? '${index + 1}',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: student.rollNumber != null
                        ? Text('Roll No: ${student.rollNumber}')
                        : null,
                    trailing: ElevatedButton(
                      onPressed: () => _addLog(student),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("Log"),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    
    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _AddLogBottomSheet extends StatefulWidget {
  final StudentModel student;
  final String classId;
  final String className;
  final TeacherModel teacher;
  final VoidCallback onLogAdded;

  const _AddLogBottomSheet({
    required this.student,
    required this.classId,
    required this.className,
    required this.teacher,
    required this.onLogAdded,
  });

  @override
  State<_AddLogBottomSheet> createState() => _AddLogBottomSheetState();
}

class _AddLogBottomSheetState extends State<_AddLogBottomSheet> {
  final BehaviourLogService _behaviourLogService = BehaviourLogService();
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  
  BehaviourType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a behavior type'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _behaviourLogService.createBehaviourLog(
        studentId: widget.student.uid,
        studentName: widget.student.name,
        classId: widget.classId,
        className: widget.className,
        behaviourType: _selectedType!,
        remark: _remarkController.text.trim(),
        date: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Behavior log saved successfully!'), backgroundColor: Colors.green),
        );
        widget.onLogAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Remark for ${widget.student.name}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              
              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.teal),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${_formatDate(_selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Behavior Type Selection
              const Text(
                'Behavior Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeedbackOption("Positive", Icons.thumb_up, Colors.green, BehaviourType.positive),
                  _buildFeedbackOption("Negative", Icons.thumb_down, Colors.red, BehaviourType.negative),
                  _buildFeedbackOption("Appreciation", Icons.star, Colors.blue, BehaviourType.appreciation),
                  _buildFeedbackOption("Neutral", Icons.chat_bubble, Colors.orange, BehaviourType.neutral),
                ],
              ),
              const SizedBox(height: 20),
              
              // Remark Text Field
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  hintText: "Enter specific comment...",
                  border: OutlineInputBorder(),
                  labelText: "Remark",
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a remark';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("SAVE LOG"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackOption(String label, IconData icon, Color color, BehaviourType type) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : color.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
