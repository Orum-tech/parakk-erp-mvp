import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/incident_log_model.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../services/incident_log_service.dart';
import '../../services/attendance_service.dart';

class IncidentLogScreen extends StatefulWidget {
  const IncidentLogScreen({super.key});

  @override
  State<IncidentLogScreen> createState() => _IncidentLogScreenState();
}

class _IncidentLogScreenState extends State<IncidentLogScreen> {
  final IncidentLogService _incidentLogService = IncidentLogService();
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  TeacherModel? _teacher;
  String? _classId;
  String? _className;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      if (teacherDoc.exists) {
        final teacher = TeacherModel.fromDocument(teacherDoc);
        setState(() {
          _teacher = teacher;
          _classId = teacher.classTeacherClassId;
        });

        // Get class name
        if (_classId != null) {
          final classDoc = await _firestore.collection('classes').doc(_classId).get();
          if (classDoc.exists) {
            setState(() {
              _className = classDoc.data()?['name'] ?? 'Unknown Class';
            });
          }
        }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Disciplinary Log", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_classId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Disciplinary Log", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No class assigned',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to be assigned as a class teacher to view incident logs',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Disciplinary Log", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search student or issue...",
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Incident List
          Expanded(
            child: StreamBuilder<List<IncidentLogModel>>(
              stream: _incidentLogService.getClassIncidentLogs(_classId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading incidents: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final incidents = snapshot.data ?? [];
                final filteredIncidents = incidents.where((incident) {
                  if (_searchQuery.isEmpty) return true;
                  final name = incident.studentName.toLowerCase();
                  final issue = incident.issue.toLowerCase();
                  return name.contains(_searchQuery) || issue.contains(_searchQuery);
                }).toList();

                if (filteredIncidents.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredIncidents.length,
                  itemBuilder: (context, index) {
                    return _buildIncidentCard(filteredIncidents[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateIncidentDialog(),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text(
          "Report Incident",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "No incidents found",
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateIncidentDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateIncidentScreen(
          classId: _classId!,
          className: _className ?? 'Unknown Class',
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildIncidentCard(IncidentLogModel incident) {
    Color severityColor;
    switch (incident.severity) {
      case IncidentSeverity.severe:
        severityColor = Colors.red;
        break;
      case IncidentSeverity.moderate:
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Severity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 18, color: severityColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      incident.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    incident.severityString.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: Issue & Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.issue,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                if (incident.actionTaken != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Action Taken: ${incident.actionTaken}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 15),
                
                // Footer: Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy').format(incident.incidentDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Status: ${incident.statusString}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Create Incident Screen
class CreateIncidentScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateIncidentScreen({super.key, required this.classId, required this.className});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final IncidentLogService _incidentLogService = IncidentLogService();
  final AttendanceService _attendanceService = AttendanceService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  StudentModel? _selectedStudent;
  List<StudentModel> _students = [];
  IncidentSeverity _selectedSeverity = IncidentSeverity.moderate;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _issueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _attendanceService.getStudentsByClass(widget.classId);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncident() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _incidentLogService.createIncidentLog(
        studentId: _selectedStudent!.uid,
        studentName: _selectedStudent!.name ?? 'Unknown',
        classId: widget.classId,
        className: widget.className,
        issue: _issueController.text.trim(),
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        incidentDate: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Report Incident", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Student Selection
                  DropdownButtonFormField<StudentModel>(
                    initialValue: _selectedStudent,
                    decoration: InputDecoration(
                      labelText: 'Select Student *',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _students.map((student) {
                      return DropdownMenuItem(
                        value: student,
                        child: Text('${student.name} (Roll: ${student.rollNumber ?? "N/A"})'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedStudent = value),
                    validator: (value) => value == null ? 'Please select a student' : null,
                  ),
                  const SizedBox(height: 20),

                  // Issue
                  TextFormField(
                    controller: _issueController,
                    decoration: InputDecoration(
                      labelText: 'Issue *',
                      hintText: 'Enter the issue title',
                      prefixIcon: const Icon(Icons.warning),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Issue is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Enter detailed description...',
                      prefixIcon: const Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 4,
                    validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Severity
                  DropdownButtonFormField<IncidentSeverity>(
                    initialValue: _selectedSeverity,
                    decoration: InputDecoration(
                      labelText: 'Severity *',
                      prefixIcon: const Icon(Icons.priority_high),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: IncidentSeverity.values.map((severity) {
                      String label;
                      switch (severity) {
                        case IncidentSeverity.minor:
                          label = 'Minor';
                          break;
                        case IncidentSeverity.moderate:
                          label = 'Moderate';
                          break;
                        case IncidentSeverity.severe:
                          label = 'Severe';
                          break;
                      }
                      return DropdownMenuItem(value: severity, child: Text(label));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSeverity = value!),
                  ),
                  const SizedBox(height: 20),

                  // Date
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incident Date *',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveIncident,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Report Incident',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}