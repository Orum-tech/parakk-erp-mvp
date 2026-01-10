import 'package:cloud_firestore/cloud_firestore.dart';

enum FeeType {
  tuition,
  bus,
  exam,
  library,
  sports,
  other,
}

enum PaymentStatus {
  pending,
  paid,
  overdue,
  partial,
}

enum PaymentMethod {
  cash,
  card,
  upi,
  bankTransfer,
  cheque,
}

class FeeModel {
  final String feeId;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final FeeType feeType;
  final String feeName;
  final double amount;
  final double? paidAmount;
  final double? dueAmount;
  final DateTime dueDate;
  final PaymentStatus status;
  final String? academicYear;
  final String? quarter; // Q1, Q2, Q3, Q4
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  FeeModel({
    required this.feeId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.feeType,
    required this.feeName,
    required this.amount,
    this.paidAmount,
    this.dueAmount,
    required this.dueDate,
    required this.status,
    this.academicYear,
    this.quarter,
    required this.createdAt,
    this.updatedAt,
  });

  String get feeTypeString {
    switch (feeType) {
      case FeeType.tuition:
        return 'Tuition Fee';
      case FeeType.bus:
        return 'Bus Fee';
      case FeeType.exam:
        return 'Exam Fee';
      case FeeType.library:
        return 'Library Fee';
      case FeeType.sports:
        return 'Sports Fee';
      case FeeType.other:
        return 'Other';
    }
  }

  String get statusString {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != PaymentStatus.paid;

  factory FeeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0.0).toDouble();
    final paidAmount = (data['paidAmount'] ?? 0.0).toDouble();
    return FeeModel(
      feeId: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      feeType: _typeFromString(data['feeType'] ?? 'Other'),
      feeName: data['feeName'] ?? '',
      amount: amount,
      paidAmount: paidAmount,
      dueAmount: amount - paidAmount,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: _statusFromString(data['status'] ?? 'Pending'),
      academicYear: data['academicYear'],
      quarter: data['quarter'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static FeeType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'tuition':
      case 'tuition fee':
        return FeeType.tuition;
      case 'bus':
      case 'bus fee':
        return FeeType.bus;
      case 'exam':
      case 'exam fee':
        return FeeType.exam;
      case 'library':
      case 'library fee':
        return FeeType.library;
      case 'sports':
      case 'sports fee':
        return FeeType.sports;
      default:
        return FeeType.other;
    }
  }

  static PaymentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'partial':
        return PaymentStatus.partial;
      default:
        return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'feeId': feeId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'feeType': feeTypeString,
      'feeName': feeName,
      'amount': amount,
      'paidAmount': paidAmount ?? 0.0,
      'dueAmount': dueAmount ?? amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': statusString,
      'academicYear': academicYear,
      'quarter': quarter,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  FeeModel copyWith({
    String? feeId,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    FeeType? feeType,
    String? feeName,
    double? amount,
    double? paidAmount,
    double? dueAmount,
    DateTime? dueDate,
    PaymentStatus? status,
    String? academicYear,
    String? quarter,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return FeeModel(
      feeId: feeId ?? this.feeId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      feeType: feeType ?? this.feeType,
      feeName: feeName ?? this.feeName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      academicYear: academicYear ?? this.academicYear,
      quarter: quarter ?? this.quarter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
