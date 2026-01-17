import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import '../../services/report_service.dart';
import '../../services/attendance_service.dart';
import '../../services/marks_service.dart';

class ClassReportsScreen extends StatefulWidget {
  const ClassReportsScreen({super.key});

  @override
  State<ClassReportsScreen> createState() => _ClassReportsScreenState();
}

class _ClassReportsScreenState extends State<ClassReportsScreen> {
  final ReportService _reportService = ReportService();
  final AttendanceService _attendanceService = AttendanceService();
  final MarksService _marksService = MarksService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _classId;
  String? _className;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  Future<void> _loadClassData() async {
    try {
      final classId = await _attendanceService.getClassTeacherClassId();
      if (classId != null) {
        // Parse className from classId (format: class_10_A)
        final parts = classId.replaceFirst('class_', '').split('_');
        final className = parts.length >= 2 ? 'Class ${parts[0]}-${parts[1]}' : classId;
        
        setState(() {
          _classId = classId;
          _className = className;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Generate Reports", style: TextStyle(color: Colors.black)),
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
          title: const Text("Generate Reports", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('You are not assigned as a class teacher'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Generate Reports", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildReportCard(context, "Attendance Report", Icons.calendar_today, Colors.blue, () => _generateAttendanceReport()),
          _buildReportCard(context, "Marks Sheet", Icons.grading, Colors.green, () => _generateMarksSheet()),
          _buildReportCard(context, "Performance Analysis", Icons.bar_chart, Colors.purple, () => _generatePerformanceAnalysis()),
          _buildReportCard(context, "Defaulters List", Icons.warning, Colors.redAccent, () => _generateDefaultersList()),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Download PDF", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAttendanceReport() async {
    if (_classId == null || _className == null) return;

    _showLoadingDialog('Generating Attendance Report...');

    try {
      final pdfFile = await _reportService.generateAttendanceReport(
        classId: _classId!,
        className: _className!,
      );

      if (mounted) Navigator.pop(context);
      _showDownloadOptions(pdfFile);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateMarksSheet() async {
    if (_classId == null || _className == null) return;

    // Get all exams for the class by fetching marks and extracting unique examIds
    try {
      final allMarks = await _marksService.getExamMarksForClass('', _classId!);
      final examIds = allMarks.map((m) => m.examId).toSet().toList();
      final examNames = <String, String>{};
      
      for (var mark in allMarks) {
        if (!examNames.containsKey(mark.examId)) {
          examNames[mark.examId] = mark.examName;
        }
      }

      if (examIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No exams found for this class'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show dialog to select exam
      final selectedExam = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Exam'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: examIds.length,
              itemBuilder: (context, index) {
                final examId = examIds[index];
                final examName = examNames[examId] ?? 'Exam';
                return ListTile(
                  title: Text(examName),
                  onTap: () => Navigator.pop(context, {
                    'examId': examId,
                    'examName': examName,
                  }),
                );
              },
            ),
          ),
        ),
      );

      if (selectedExam == null) return;

      _showLoadingDialog('Generating Marks Sheet...');

      try {
        final pdfFile = await _reportService.generateMarksSheet(
          classId: _classId!,
          className: _className!,
          examId: selectedExam['examId']!,
          examName: selectedExam['examName']!,
        );

        if (mounted) Navigator.pop(context);
        _showDownloadOptions(pdfFile);
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generating report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePerformanceAnalysis() async {
    if (_classId == null || _className == null) return;

    _showLoadingDialog('Generating Performance Analysis...');

    try {
      final pdfFile = await _reportService.generatePerformanceAnalysis(
        classId: _classId!,
        className: _className!,
      );

      if (mounted) Navigator.pop(context);
      _showDownloadOptions(pdfFile);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateDefaultersList() async {
    if (_classId == null || _className == null) return;

    _showLoadingDialog('Generating Defaulters List...');

    try {
      final pdfFile = await _reportService.generateDefaultersList(
        classId: _classId!,
        className: _className!,
      );

      if (mounted) Navigator.pop(context);
      _showDownloadOptions(pdfFile);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDownloadOptions(File pdfFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Generated'),
        content: const Text('What would you like to do with the report?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareReport(pdfFile);
            },
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _viewReport(pdfFile);
            },
            child: const Text('View'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareReport(pdfFile);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReport(File pdfFile) async {
    try {
      final xFile = XFile(pdfFile.path);
      await Share.shareXFiles([xFile]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewReport(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}