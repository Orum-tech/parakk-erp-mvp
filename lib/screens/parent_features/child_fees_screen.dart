import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';

class ChildFeesScreen extends StatefulWidget {
  final StudentModel child;

  const ChildFeesScreen({super.key, required this.child});

  @override
  State<ChildFeesScreen> createState() => _ChildFeesScreenState();
}

class _ChildFeesScreenState extends State<ChildFeesScreen> {
  final ParentService _parentService = ParentService();
  Map<String, dynamic>? _feeSummary;
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadFeeSummary();
  }

  Future<void> _loadFeeSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final summary = await _parentService.getChildFeeSummary(widget.child.uid);
      setState(() => _feeSummary = summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDue = _feeSummary?['totalDue'] ?? 0.0;
    final totalPaid = _feeSummary?['totalPaid'] ?? 0.0;
    final pendingCount = _feeSummary?['pendingCount'] ?? 0;
    final overdueCount = _feeSummary?['overdueCount'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("${widget.child.name}'s Fees", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Summary Card
          if (_isLoadingSummary)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: totalDue > 0
                      ? [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)]
                      : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (totalDue > 0 ? Colors.purple : Colors.green).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text("Total Outstanding", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text(
                    "₹ ${totalDue.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  if (overdueCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$overdueCount overdue payment(s)",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  if (pendingCount > 0 && overdueCount == 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$pendingCount pending payment(s)",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  if (totalDue == 0) ...[
                    const SizedBox(height: 10),
                    const Text("All fees paid!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ],
              ),
            ),

          // Fee List
          Expanded(
            child: StreamBuilder<List<FeeModel>>(
              stream: _parentService.getChildFees(widget.child.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                final feesList = snapshot.data ?? [];

                if (feesList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No fee records found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                // Separate by status
                final overdue = feesList.where((f) => f.isOverdue).toList();
                final pending = feesList.where((f) => f.status == PaymentStatus.pending && !f.isOverdue).toList();
                final paid = feesList.where((f) => f.status == PaymentStatus.paid).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overdue.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text("Overdue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                        ...overdue.map((fee) => _buildFeeCard(fee)),
                        const SizedBox(height: 20),
                      ],
                      if (pending.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text("Pending", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...pending.map((fee) => _buildFeeCard(fee)),
                        const SizedBox(height: 20),
                      ],
                      if (paid.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Text("Paid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...paid.map((fee) => _buildFeeCard(fee)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(FeeModel fee) {
    final isOverdue = fee.isOverdue;
    final isPaid = fee.status == PaymentStatus.paid;
    final isPending = fee.status == PaymentStatus.pending && !isOverdue;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaid) {
      statusColor = Colors.green;
      statusText = 'Paid';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
      statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue ? Border.all(color: Colors.red.withOpacity(0.3), width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.feeName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fee.feeTypeString,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Amount",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹ ${fee.amount.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (!isPaid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Due Amount",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹ ${(fee.dueAmount ?? fee.amount).toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              if (isPaid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Paid Amount",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹ ${(fee.paidAmount ?? 0).toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Due: ${_formatDate(fee.dueDate)}',
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (fee.quarter != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fee.quarter!,
                    style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
