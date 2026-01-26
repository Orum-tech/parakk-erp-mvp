import 'package:flutter/material.dart';
import '../services/school_context_service.dart';
import '../services/school_service.dart';
import '../models/school_model.dart';
import 'auth_wrapper.dart';

class SchoolSelectionScreen extends StatefulWidget {
  final List<String> schoolIds;

  const SchoolSelectionScreen({super.key, required this.schoolIds});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  final _schoolService = SchoolService();
  final _schoolContextService = SchoolContextService();
  List<SchoolModel> _schools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final schools = <SchoolModel>[];
      for (final schoolId in widget.schoolIds) {
        final school = await _schoolService.getSchoolById(schoolId);
        if (school != null && school.isSubscriptionActive) {
          schools.add(school);
        }
      }
      setState(() {
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schools: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectSchool(SchoolModel school) async {
    try {
      await _schoolContextService.setSchoolContext(school.schoolId);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select school: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select School'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schools.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No active schools found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schools.length,
                  itemBuilder: (context, index) {
                    final school = _schools[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Color(0xFF1565C0),
                            size: 30,
                          ),
                        ),
                        title: Text(
                          school.schoolName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Code: ${school.schoolCode}'),
                            const SizedBox(height: 4),
                            _buildSubscriptionBadge(school.subscriptionStatus),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                        onTap: () => _selectSchool(school),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSubscriptionBadge(SubscriptionStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case SubscriptionStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case SubscriptionStatus.trial:
        color = Colors.orange;
        text = 'Trial';
        break;
      case SubscriptionStatus.expired:
        color = Colors.red;
        text = 'Expired';
        break;
      case SubscriptionStatus.suspended:
        color = Colors.red;
        text = 'Suspended';
        break;
      case SubscriptionStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
