import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/leave_request_model.dart';
import '../../models/teacher_model.dart';
import '../../services/leave_request_service.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  final LeaveRequestService _leaveRequestService = LeaveRequestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TeacherModel? _teacher;
  String? _classId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
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

  Future<void> _approveLeave(LeaveRequestModel leave) async {
    try {
      await _leaveRequestService.approveLeaveRequest(leave.leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request approved'),
            backgroundColor: Colors.green,
          ),
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

  Future<void> _rejectLeave(LeaveRequestModel leave) async {
    String? rejectionReason;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Rejection Reason (Optional)',
            hintText: 'Enter reason for rejection...',
          ),
          maxLines: 3,
          onChanged: (value) => rejectionReason = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, rejectionReason),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null || rejectionReason != null) {
      try {
        await _leaveRequestService.rejectLeaveRequest(leave.leaveId, rejectionReason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave request rejected'),
              backgroundColor: Colors.orange,
            ),
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

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text("Leave Applications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          title: const Text("Leave Applications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                'You need to be assigned as a class teacher to view leave requests',
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
        title: const Text("Leave Applications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<LeaveRequestModel>>(
        stream: _classId != null 
            ? _leaveRequestService.getClassLeaveRequests(_classId!)
            : Stream.value([]),
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
                    'Error loading leave requests: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final leaves = snapshot.data ?? [];

          if (leaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No leave requests',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave requests from students will appear here',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              ...leaves.map((leave) => _buildRequestCard(leave)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(LeaveRequestModel leave) {
    final statusColor = _getStatusColor(leave.status);
    final dateFormat = DateFormat('dd MMM yyyy');
    final duration = '${leave.numberOfDays} Day${leave.numberOfDays != 1 ? 's' : ''} (${dateFormat.format(leave.startDate)} - ${dateFormat.format(leave.endDate)})';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
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
                      leave.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leave.className,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leave.statusString,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${leave.leaveTypeString} • $duration",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            leave.reason,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          if (leave.status == LeaveStatus.approved && leave.approvedByName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Approved by ${leave.approvedByName}',
              style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
          ],
          if (leave.status == LeaveStatus.rejected && leave.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${leave.rejectionReason}',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
          if (leave.status == LeaveStatus.pending) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectLeave(leave),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveLeave(leave),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}