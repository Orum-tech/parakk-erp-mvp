import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/leave_request_model.dart';
import '../../models/student_model.dart';
import '../../services/leave_request_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  final StudentModel? child;

  const LeaveRequestScreen({super.key, this.child});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final LeaveRequestService _leaveRequestService = LeaveRequestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  StudentModel? _selectedChild;
  List<StudentModel> _children = [];
  LeaveType _selectedLeaveType = LeaveType.personal;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.child;
    _loadChildren();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get parent's children
      final childrenSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('parentId', isEqualTo: user.uid)
          .get();

      final children = childrenSnapshot.docs
          .map((doc) => StudentModel.fromDocument(doc))
          .toList();

      setState(() {
        _children = children;
        if (_selectedChild == null && children.isNotEmpty) {
          _selectedChild = children.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading children: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End date must be after start date'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Get class name
      String className = 'Unknown Class';
      if (_selectedChild!.classId != null) {
        final classDoc = await _firestore.collection('classes').doc(_selectedChild!.classId).get();
        if (classDoc.exists) {
          className = classDoc.data()?['name'] ?? 'Unknown Class';
        }
      }

      await _leaveRequestService.createLeaveRequest(
        studentId: _selectedChild!.uid,
        studentName: _selectedChild!.name ?? 'Unknown',
        classId: _selectedChild!.classId ?? '',
        className: className,
        leaveType: _selectedLeaveType,
        reason: _reasonController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset form
        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Leave Request", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1565C0),
            tabs: [
              Tab(text: 'New Request', icon: Icon(Icons.add_circle_outline)),
              Tab(text: 'My Requests', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildNewRequestTab(),
                  _buildMyRequestsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildNewRequestTab() {
    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No children found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Please ensure your account is linked to a student',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Child Selection
          if (_children.length > 1)
            DropdownButtonFormField<StudentModel>(
              initialValue: _selectedChild,
              decoration: InputDecoration(
                labelText: 'Select Child *',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _children.map((child) {
                return DropdownMenuItem(
                  value: child,
                  child: Text('${child.name} (${child.className ?? "Unknown Class"})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedChild = value),
            )
          else if (_selectedChild != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedChild!.name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedChild!.className ?? 'Unknown Class',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Leave Type
          DropdownButtonFormField<LeaveType>(
            initialValue: _selectedLeaveType,
            decoration: InputDecoration(
              labelText: 'Leave Type *',
              prefixIcon: const Icon(Icons.category),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: LeaveType.values.map((type) {
              String label;
              switch (type) {
                case LeaveType.medical:
                  label = 'Medical Leave';
                  break;
                case LeaveType.personal:
                  label = 'Personal Leave';
                  break;
                case LeaveType.familyFunction:
                  label = 'Family Function';
                  break;
                case LeaveType.emergency:
                  label = 'Emergency';
                  break;
                case LeaveType.other:
                  label = 'Other';
                  break;
              }
              return DropdownMenuItem(value: type, child: Text(label));
            }).toList(),
            onChanged: (value) => setState(() => _selectedLeaveType = value!),
          ),
          const SizedBox(height: 20),

          // Start Date
          _buildDateField('Start Date *', _startDate, true),
          const SizedBox(height: 20),

          // End Date
          _buildDateField('End Date *', _endDate, false),
          const SizedBox(height: 20),

          // Reason
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason *',
              hintText: 'Enter reason for leave...',
              prefixIcon: const Icon(Icons.description),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 4,
            validator: (value) => value?.isEmpty ?? true ? 'Reason is required' : null,
          ),
          const SizedBox(height: 30),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLeaveRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Leave Request',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isStartDate) {
    return InkWell(
      onTap: () => _selectDate(isStartDate),
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
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_selectedChild == null) {
      return const Center(
        child: Text('Please select a child first'),
      );
    }

    return StreamBuilder<List<LeaveRequestModel>>(
      stream: _leaveRequestService.getStudentLeaveRequests(_selectedChild!.uid),
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
                  'Your leave requests will appear here',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...leaves.map((leave) => _buildLeaveCard(leave)),
          ],
        );
      },
    );
  }

  Widget _buildLeaveCard(LeaveRequestModel leave) {
    final statusColor = _getStatusColor(leave.status);
    final dateFormat = DateFormat('dd MMM yyyy');
    final duration = '${leave.numberOfDays} Day${leave.numberOfDays != 1 ? 's' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
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
                      leave.leaveTypeString,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(leave.startDate)} - ${dateFormat.format(leave.endDate)}',
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
          const SizedBox(height: 12),
          Text(
            leave.reason,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                duration,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (leave.status == LeaveStatus.approved && leave.approvedByName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Approved by ${leave.approvedByName}',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ],
            ),
          ],
          if (leave.status == LeaveStatus.rejected && leave.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cancel, size: 14, color: Colors.red[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Rejected: ${leave.rejectionReason}',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (leave.status == LeaveStatus.pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Leave Request?'),
                      content: const Text('Are you sure you want to delete this pending leave request?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await _leaveRequestService.deleteLeaveRequest(leave.leaveId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Leave request deleted'),
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
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Delete Request'),
              ),
            ),
          ],
        ],
      ),
    );
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
}
