import 'package:cloud_firestore/cloud_firestore.dart';
import 'fee_model.dart';

class FeeTransactionModel {
  final String transactionId;
  final String feeId;
  final String studentId;
  final String studentName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? transactionReference;
  final String? receiptNumber;
  final DateTime transactionDate;
  final String? processedBy;
  final String? notes;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  FeeTransactionModel({
    required this.transactionId,
    required this.feeId,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.paymentMethod,
    this.transactionReference,
    this.receiptNumber,
    required this.transactionDate,
    this.processedBy,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  String get paymentMethodString {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cheque:
        return 'Cheque';
    }
  }

  factory FeeTransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeeTransactionModel(
      transactionId: doc.id,
      feeId: data['feeId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: _methodFromString(data['paymentMethod'] ?? 'Cash'),
      transactionReference: data['transactionReference'],
      receiptNumber: data['receiptNumber'],
      transactionDate: (data['transactionDate'] as Timestamp).toDate(),
      processedBy: data['processedBy'],
      notes: data['notes'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static PaymentMethod _methodFromString(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'upi':
        return PaymentMethod.upi;
      case 'banktransfer':
      case 'bank transfer':
        return PaymentMethod.bankTransfer;
      case 'cheque':
        return PaymentMethod.cheque;
      default:
        return PaymentMethod.cash;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'feeId': feeId,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'paymentMethod': paymentMethodString,
      'transactionReference': transactionReference,
      'receiptNumber': receiptNumber,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'processedBy': processedBy,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  FeeTransactionModel copyWith({
    String? transactionId,
    String? feeId,
    String? studentId,
    String? studentName,
    double? amount,
    PaymentMethod? paymentMethod,
    String? transactionReference,
    String? receiptNumber,
    DateTime? transactionDate,
    String? processedBy,
    String? notes,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return FeeTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      feeId: feeId ?? this.feeId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      processedBy: processedBy ?? this.processedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
