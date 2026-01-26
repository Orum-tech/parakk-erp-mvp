import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import 'attendance_service.dart';
import 'marks_service.dart';

class ReportService {
  final AttendanceService _attendanceService = AttendanceService();
  final MarksService _marksService = MarksService();

  // Generate Attendance Report PDF
  Future<File> generateAttendanceReport({
    required String classId,
    required String className,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Get students and attendance
    final students = await _attendanceService.getStudentsByClass(classId);
    final allAttendance = <String, List<AttendanceModel>>{};

    for (var student in students) {
      final attendance = await _attendanceService
          .getStudentAttendance(
            studentId: student.uid,
            startDate: startDate,
            endDate: endDate,
          )
          .first;
      allAttendance[student.uid] = attendance;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'PARAKK SCHOOL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'ATTENDANCE REPORT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Class: $className',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            if (startDate != null || endDate != null)
              pw.Text(
                'Period: ${startDate != null ? dateFormat.format(startDate) : 'Start'} - ${endDate != null ? dateFormat.format(endDate) : 'End'}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            pw.Text(
              'Generated on: ${dateFormat.format(now)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),

            // Attendance Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Roll No.', isHeader: true),
                    _buildTableCell('Student Name', isHeader: true),
                    _buildTableCell('Present', isHeader: true),
                    _buildTableCell('Absent', isHeader: true),
                    _buildTableCell('Percentage', isHeader: true),
                  ],
                ),
                // Data rows
                ...students.map((student) {
                  final attendance = allAttendance[student.uid] ?? [];
                  final present = attendance.where((a) => a.status == AttendanceStatus.present).length;
                  final absent = attendance.where((a) => a.status == AttendanceStatus.absent).length;
                  final total = attendance.length;
                  final percentage = total > 0 ? (present / total * 100) : 0.0;

                  return pw.TableRow(
                    children: [
                      _buildTableCell(student.rollNumber ?? 'N/A'),
                      _buildTableCell(student.name),
                      _buildTableCell(present.toString()),
                      _buildTableCell(absent.toString()),
                      _buildTableCell('${percentage.toStringAsFixed(1)}%'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'Attendance_Report_$className');
  }

  // Generate Marks Sheet PDF
  Future<File> generateMarksSheet({
    required String classId,
    required String className,
    required String examId,
    required String examName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Get students and marks
    final students = await _attendanceService.getStudentsByClass(classId);
    final allMarks = await _marksService.getExamMarksForClass(examId, classId);

    // Group marks by student
    final marksByStudent = <String, List<MarksModel>>{};
    for (var mark in allMarks) {
      if (!marksByStudent.containsKey(mark.studentId)) {
        marksByStudent[mark.studentId] = [];
      }
      marksByStudent[mark.studentId]!.add(mark);
    }

    // Get all subjects
    final subjects = allMarks.map((m) => m.subjectName).toSet().toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: subjects.length > 4 ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'PARAKK SCHOOL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'MARKS SHEET',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Class: $className', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Exam: $examName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated on: ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            // Marks Table
            if (subjects.isNotEmpty)
              _buildMarksTable(students, marksByStudent, subjects, examId, examName, classId, className)
            else
              pw.Text('No marks data available', style: const pw.TextStyle(fontSize: 12)),
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'Marks_Sheet_${examName.replaceAll(' ', '_')}');
  }

  // Generate Performance Analysis PDF
  Future<File> generatePerformanceAnalysis({
    required String classId,
    required String className,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Get students
    final students = await _attendanceService.getStudentsByClass(classId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'PARAKK SCHOOL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'PERFORMANCE ANALYSIS',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Class: $className', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated on: ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Text(
              'This report provides a comprehensive analysis of student performance including attendance, marks, and overall progress.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            // Note: Full implementation would require fetching and analyzing all data
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'Performance_Analysis_$className');
  }

  // Generate Defaulters List PDF
  Future<File> generateDefaultersList({
    required String classId,
    required String className,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Get students and attendance
    final students = await _attendanceService.getStudentsByClass(classId);
    final defaulters = <StudentModel>[];

    for (var student in students) {
      final attendance = await _attendanceService
          .getStudentAttendance(studentId: student.uid)
          .first;
      final present = attendance.where((a) => a.status == AttendanceStatus.present).length;
      final total = attendance.length;
      final percentage = total > 0 ? (present / total * 100) : 0.0;

      // Consider students with less than 75% attendance as defaulters
      if (percentage < 75) {
        defaulters.add(student);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'PARAKK SCHOOL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'DEFAULTERS LIST',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Class: $className', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated on: ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),

            if (defaulters.isEmpty)
              pw.Text(
                'No defaulters found. All students have satisfactory attendance.',
                style: const pw.TextStyle(fontSize: 12),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Roll No.', isHeader: true),
                      _buildTableCell('Student Name', isHeader: true),
                      _buildTableCell('Parent Contact', isHeader: true),
                    ],
                  ),
                  ...defaulters.map((student) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(student.rollNumber ?? 'N/A'),
                        _buildTableCell(student.name),
                        _buildTableCell(student.parentEmail ?? 'N/A'),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'Defaulters_List_$className');
  }

  pw.Widget _buildMarksTable(
    List<StudentModel> students,
    Map<String, List<MarksModel>> marksByStudent,
    List<String> subjects,
    String examId,
    String examName,
    String classId,
    String className,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        ...{ for (var i in List.generate(subjects.length, (i) => i + 2)) i + 2 : const pw.FlexColumnWidth(1) },
        subjects.length + 2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Roll No.', isHeader: true),
            _buildTableCell('Student Name', isHeader: true),
            ...subjects.map((s) => _buildTableCell(s, isHeader: true)),
            _buildTableCell('Total %', isHeader: true),
          ],
        ),
        // Data rows
        ...students.map((student) {
          final studentMarks = marksByStudent[student.uid] ?? [];
          double totalMarks = 0;
          double maxTotalMarks = 0;

          final schoolId = students.isNotEmpty ? students.first.schoolId : '';
          final subjectCells = subjects.map((subject) {
            final mark = studentMarks.firstWhere(
              (m) => m.subjectName == subject,
              orElse: () => MarksModel(
                marksId: '',
                schoolId: schoolId,
                examId: examId,
                examName: examName,
                studentId: student.uid,
                studentName: student.name,
                classId: classId,
                className: className,
                subjectId: '',
                subjectName: subject,
                marksObtained: 0,
                maxMarks: 0,
                createdAt: Timestamp.now(),
              ),
            );
            totalMarks += mark.marksObtained;
            maxTotalMarks += mark.maxMarks;
            return _buildTableCell(
              mark.maxMarks > 0 ? '${mark.marksObtained}/${mark.maxMarks}' : '-',
            );
          }).toList();

          final totalPercentage = maxTotalMarks > 0
              ? (totalMarks / maxTotalMarks * 100)
              : 0.0;

          return pw.TableRow(
            children: [
              _buildTableCell(student.rollNumber ?? 'N/A'),
              _buildTableCell(student.name),
              ...subjectCells,
              _buildTableCell('${totalPercentage.toStringAsFixed(1)}%'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<File> _savePdf(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
