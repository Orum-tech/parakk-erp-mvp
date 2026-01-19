import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/marks_model.dart';
import '../models/student_model.dart';

class MarksheetService {
  // Generate PDF marksheet
  Future<File> generateMarksheetPDF({
    required StudentModel student,
    required List<MarksModel> marks,
    required String examName,
    String? examDate,
    double? cgpa,
    String? overallGrade,
    int? rank,
    String? schoolName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Calculate totals
    double totalMarks = 0;
    double maxTotalMarks = 0;
    for (var mark in marks) {
      totalMarks += mark.marksObtained;
      maxTotalMarks += mark.maxMarks;
    }
    final totalPercentage = maxTotalMarks > 0 ? (totalMarks / maxTotalMarks) * 100 : 0.0;

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
                    schoolName ?? 'Study Buddy SCHOOL',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'ACADEMIC MARKSHEET',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Student Information
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STUDENT INFORMATION',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Name', student.name),
                  _buildInfoRow('Roll Number', student.rollNumber ?? 'N/A'),
                  _buildInfoRow('Class', student.className ?? 'N/A'),
                  _buildInfoRow('Section', student.section ?? 'N/A'),
                  _buildInfoRow('Academic Year', '${now.year - 1}-${now.year}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Exam Information
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EXAM INFORMATION',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Exam Name', examName),
                  if (examDate != null) _buildInfoRow('Exam Date', examDate),
                  _buildInfoRow('Date of Issue', dateFormat.format(now)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Subject-wise Marks Table
            pw.Text(
              'SUBJECT-WISE PERFORMANCE',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Subject', isHeader: true),
                    _buildTableCell('Marks Obtained', isHeader: true),
                    _buildTableCell('Max Marks', isHeader: true),
                    _buildTableCell('Percentage', isHeader: true),
                    _buildTableCell('Grade', isHeader: true),
                  ],
                ),
                // Data rows
                ...marks.map((mark) {
                  final percentage = mark.percentage;
                  final grade = mark.grade ?? mark.calculateGrade();
                  return pw.TableRow(
                    children: [
                      _buildTableCell(mark.subjectName),
                      _buildTableCell(mark.marksObtained.toString()),
                      _buildTableCell(mark.maxMarks.toString()),
                      _buildTableCell('${percentage.toStringAsFixed(1)}%'),
                      _buildTableCell(grade, color: _getGradeColor(grade)),
                    ],
                  );
                }),
                // Total row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('TOTAL', isHeader: true),
                    _buildTableCell(totalMarks.toStringAsFixed(0), isHeader: true),
                    _buildTableCell(maxTotalMarks.toStringAsFixed(0), isHeader: true),
                    _buildTableCell('${totalPercentage.toStringAsFixed(1)}%', isHeader: true),
                    _buildTableCell(overallGrade ?? 'N/A', isHeader: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue300, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CGPA',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        cgpa != null ? cgpa.toStringAsFixed(2) : 'N/A',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rank != null && rank > 0)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      border: pw.Border.all(color: PdfColors.green300, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CLASS RANK',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '$rank${rank == 1 ? 'st' : rank == 2 ? 'nd' : rank == 3 ? 'rd' : 'th'}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Class Teacher',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      '_________________',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Principal',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      '_________________',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated document. No signature is required.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Marksheet_${student.name.replaceAll(' ', '_')}_${examName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.blue900 : PdfColors.black),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  PdfColor _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return PdfColors.green700;
      case 'A':
        return PdfColors.green600;
      case 'B+':
        return PdfColors.blue700;
      case 'B':
        return PdfColors.blue600;
      case 'C+':
        return PdfColors.orange700;
      case 'C':
        return PdfColors.orange600;
      default:
        return PdfColors.red700;
    }
  }
}
