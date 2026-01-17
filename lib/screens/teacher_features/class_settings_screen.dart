import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/class_settings_service.dart';
import '../../services/attendance_service.dart';
import '../../models/class_model.dart';
import '../../models/teacher_model.dart';

class ClassSettingsScreen extends StatefulWidget {
  const ClassSettingsScreen({super.key});

  @override
  State<ClassSettingsScreen> createState() => _ClassSettingsScreenState();
}

class _ClassSettingsScreenState extends State<ClassSettingsScreen> {
  final ClassSettingsService _settingsService = ClassSettingsService();
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ClassModel? _classData;
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _classId;
  int _totalStudents = 0;
  List<Map<String, dynamic>> _subjects = [];

  // Controllers
  final TextEditingController _academicYearController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lateCutoffController = TextEditingController();
  final TextEditingController _autoAbsentController = TextEditingController();
  final TextEditingController _passingMarksController = TextEditingController();
  final TextEditingController _latePenaltyController = TextEditingController();
  final TextEditingController _maxLateDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _academicYearController.dispose();
    _descriptionController.dispose();
    _lateCutoffController.dispose();
    _autoAbsentController.dispose();
    _passingMarksController.dispose();
    _latePenaltyController.dispose();
    _maxLateDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get teacher's class
      _classId = await _attendanceService.getClassTeacherClassId();
      if (_classId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load class data
      _classData = await _settingsService.getClassData(_classId!);
      if (_classData == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load settings
      _settings = await _settingsService.getClassSettings(_classId!);

      // Load additional data
      _totalStudents = await _settingsService.getTotalStudents(_classId!);
      _subjects = await _settingsService.getClassSubjects(_classId!);

      // Set controllers
      _academicYearController.text = _classData!.academicYear ?? '';
      _descriptionController.text = _settings['description'] ?? '';
      _lateCutoffController.text = _settings['lateAttendanceCutoff'] ?? '09:00';
      _autoAbsentController.text = _settings['autoMarkAbsentAfter'] ?? '10:00';
      _passingMarksController.text = (_settings['passingMarks'] ?? 33).toString();
      _latePenaltyController.text = (_settings['lateSubmissionPenalty'] ?? 0).toString();
      _maxLateDaysController.text = (_settings['maxLateSubmissionDays'] ?? 3).toString();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_classId == null) return;

    setState(() => _isSaving = true);
    try {
      // Update class info
      await _settingsService.updateClassInfo(
        classId: _classId!,
        academicYear: _academicYearController.text.trim().isEmpty
            ? null
            : _academicYearController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Update settings
      final updatedSettings = Map<String, dynamic>.from(_settings);
      updatedSettings['lateAttendanceCutoff'] = _lateCutoffController.text;
      updatedSettings['autoMarkAbsentAfter'] = _autoAbsentController.text;
      updatedSettings['passingMarks'] = int.tryParse(_passingMarksController.text) ?? 33;
      updatedSettings['lateSubmissionPenalty'] = int.tryParse(_latePenaltyController.text) ?? 0;
      updatedSettings['maxLateSubmissionDays'] = int.tryParse(_maxLateDaysController.text) ?? 3;
      updatedSettings['description'] = _descriptionController.text.trim();

      await _settingsService.updateClassSettings(_classId!, updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("Class Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_classData == null || _classId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F4),
        appBar: AppBar(
          title: const Text("Class Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No class assigned',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to be assigned as a class teacher to access settings',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Class Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text(
              _classData!.fullClassName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Overview Card
              _buildOverviewCard(),
              const SizedBox(height: 20),

              // Class Information
              _buildSectionHeader('Class Information', Icons.info_outline),
              const SizedBox(height: 10),
              _buildClassInfoSection(),
              const SizedBox(height: 20),

              // Attendance Settings
              _buildSectionHeader('Attendance Settings', Icons.fact_check),
              const SizedBox(height: 10),
              _buildAttendanceSettings(),
              const SizedBox(height: 20),

              // Homework Settings
              _buildSectionHeader('Homework Settings', Icons.assignment),
              const SizedBox(height: 10),
              _buildHomeworkSettings(),
              const SizedBox(height: 20),

              // Grading Settings
              _buildSectionHeader('Grading Settings', Icons.grade),
              const SizedBox(height: 10),
              _buildGradingSettings(),
              const SizedBox(height: 20),

              // Communication Settings
              _buildSectionHeader('Communication Settings', Icons.chat),
              const SizedBox(height: 10),
              _buildCommunicationSettings(),
              const SizedBox(height: 20),

              // Privacy Settings
              _buildSectionHeader('Privacy Settings', Icons.privacy_tip),
              const SizedBox(height: 10),
              _buildPrivacySettings(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
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
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_, color: Color(0xFF00897B), size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _classData!.fullClassName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_classData!.classTeacherName != null)
                      Text(
                        'Class Teacher: ${_classData!.classTeacherName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Students', _totalStudents.toString(), Icons.people),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem('Subjects', _subjects.length.toString(), Icons.book),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00897B), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
        ),
      ],
    );
  }

  Widget _buildClassInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _academicYearController,
            decoration: const InputDecoration(
              labelText: 'Academic Year',
              hintText: 'e.g., 2024-2025',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Class Description (Optional)',
              hintText: 'Add any notes about this class...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Allow Late Attendance',
            'Students can mark attendance after the cutoff time',
            _settings['allowLateAttendance'] ?? true,
            (val) => _updateSetting('allowLateAttendance', val),
          ),
          if (_settings['allowLateAttendance'] == true) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _lateCutoffController,
              decoration: const InputDecoration(
                labelText: 'Late Attendance Cutoff Time',
                hintText: 'HH:mm (e.g., 09:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
          ],
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Auto-Mark Absent',
            'Automatically mark students absent after specified time',
            _settings['autoMarkAbsentAfter'] != null,
            (val) => _updateSetting('autoMarkAbsentAfter', val ? _autoAbsentController.text : null),
          ),
          if (_settings['autoMarkAbsentAfter'] != null) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _autoAbsentController,
              decoration: const InputDecoration(
                labelText: 'Auto-Mark Absent After',
                hintText: 'HH:mm (e.g., 10:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
          ],
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Require Reason for Absence',
            'Students must provide a reason when marking absent',
            _settings['requireReasonForAbsence'] ?? false,
            (val) => _updateSetting('requireReasonForAbsence', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Allow Parents to Mark Attendance',
            'Parents can mark attendance on behalf of students',
            _settings['allowParentMarkAttendance'] ?? false,
            (val) => _updateSetting('allowParentMarkAttendance', val),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Auto-Lock Homework',
            'Automatically close submissions after deadline',
            _settings['autoLockHomework'] ?? false,
            (val) => _updateSetting('autoLockHomework', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Allow Late Submission',
            'Students can submit homework after deadline',
            _settings['allowLateSubmission'] ?? true,
            (val) => _updateSetting('allowLateSubmission', val),
          ),
          if (_settings['allowLateSubmission'] == true) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latePenaltyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Late Penalty (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxLateDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Late Days',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Require Attachment',
            'Students must attach files with homework submission',
            _settings['requireAttachment'] ?? false,
            (val) => _updateSetting('requireAttachment', val),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _passingMarksController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Passing Marks (%)',
              hintText: 'e.g., 33',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.check_circle),
            ),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Show Ranks to Students',
            'Display class rank in results',
            _settings['showRanksToStudents'] ?? true,
            (val) => _updateSetting('showRanksToStudents', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Show Grades to Students',
            'Students can view their grades',
            _settings['showGradesToStudents'] ?? true,
            (val) => _updateSetting('showGradesToStudents', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Round Off Marks',
            'Automatically round marks to nearest whole number',
            _settings['roundOffMarks'] ?? true,
            (val) => _updateSetting('roundOffMarks', val),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Mute Group Chat',
            'Only admins can send messages in class group',
            _settings['muteGroupChat'] ?? false,
            (val) => _updateSetting('muteGroupChat', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Allow Student Messages',
            'Students can send direct messages to teacher',
            _settings['allowStudentMessages'] ?? true,
            (val) => _updateSetting('allowStudentMessages', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Allow Parent Messages',
            'Parents can send direct messages to teacher',
            _settings['allowParentMessages'] ?? true,
            (val) => _updateSetting('allowParentMessages', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Notify on Homework',
            'Send notifications when homework is assigned',
            _settings['notifyOnHomework'] ?? true,
            (val) => _updateSetting('notifyOnHomework', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Notify on Test',
            'Send notifications when tests are scheduled',
            _settings['notifyOnTest'] ?? true,
            (val) => _updateSetting('notifyOnTest', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Notify on Attendance',
            'Send notifications about attendance updates',
            _settings['notifyOnAttendance'] ?? false,
            (val) => _updateSetting('notifyOnAttendance', val),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Show Class Rank',
            'Display overall class rank to students',
            _settings['showClassRank'] ?? true,
            (val) => _updateSetting('showClassRank', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Show Subject Rank',
            'Display subject-wise rank to students',
            _settings['showSubjectRank'] ?? false,
            (val) => _updateSetting('showSubjectRank', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Show Attendance to Parents',
            'Parents can view their child\'s attendance',
            _settings['showAttendanceToParents'] ?? true,
            (val) => _updateSetting('showAttendanceToParents', val),
          ),
          const SizedBox(height: 15),
          _buildSwitchTile(
            'Show Marks to Parents',
            'Parents can view their child\'s marks',
            _settings['showMarksToParents'] ?? true,
            (val) => _updateSetting('showMarksToParents', val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      activeColor: const Color(0xFF00897B),
    );
  }
}
