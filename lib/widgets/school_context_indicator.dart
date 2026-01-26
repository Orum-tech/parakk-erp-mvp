import 'package:flutter/material.dart';
import '../models/school_model.dart';
import '../services/school_context_service.dart';

class SchoolContextIndicator extends StatelessWidget {
  final SchoolContextService _schoolContextService = SchoolContextService();

  SchoolContextIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchoolModel?>(
      future: _schoolContextService.getCurrentSchool(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final school = snapshot.data;
        if (school == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(school.subscriptionStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(school.subscriptionStatus).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school,
                size: 14,
                color: _getStatusColor(school.subscriptionStatus),
              ),
              const SizedBox(width: 6),
              Text(
                school.schoolCode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(school.subscriptionStatus),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.trial:
        return Colors.orange;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.suspended:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.grey;
    }
  }
}

class SchoolNameHeader extends StatelessWidget {
  final SchoolContextService _schoolContextService = SchoolContextService();

  SchoolNameHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchoolModel?>(
      future: _schoolContextService.getCurrentSchool(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final school = snapshot.data;
        if (school == null) {
          return const SizedBox.shrink();
        }

        return Text(
          school.schoolName,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
