import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import '../../models/event_model.dart';

class EventsScreen extends StatelessWidget {
  final String? classId;

  const EventsScreen({super.key, this.classId});

  @override
  Widget build(BuildContext context) {
    final parentService = ParentService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Events", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: parentService.getEvents(classId),
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

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No events scheduled', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          // Separate upcoming and past events
          final now = DateTime.now();
          final upcoming = events.where((e) => e.eventDate.isAfter(now) || e.eventDate.isAtSameMomentAs(now)).toList()
            ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
          final past = events.where((e) => e.eventDate.isBefore(now)).toList()
            ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (upcoming.isNotEmpty) ...[
                  const Text("Upcoming Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...upcoming.map((event) => _buildEventCard(event, isUpcoming: true)),
                  const SizedBox(height: 30),
                ],
                if (past.isNotEmpty) ...[
                  const Text("Past Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  ...past.map((event) => _buildEventCard(event, isUpcoming: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event, {required bool isUpcoming}) {
    Color categoryColor;
    IconData categoryIcon;

    switch (event.category) {
      case EventCategory.sports:
        categoryColor = Colors.orange;
        categoryIcon = Icons.sports_soccer;
        break;
      case EventCategory.academic:
        categoryColor = Colors.blue;
        categoryIcon = Icons.school;
        break;
      case EventCategory.cultural:
        categoryColor = Colors.purple;
        categoryIcon = Icons.palette;
        break;
      case EventCategory.meeting:
        categoryColor = Colors.green;
        categoryIcon = Icons.people;
        break;
      case EventCategory.holiday:
        categoryColor = Colors.amber;
        categoryIcon = Icons.beach_access;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.event;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUpcoming ? Border.all(color: categoryColor.withOpacity(0.3), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.categoryString,
                      style: TextStyle(color: categoryColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description!,
              style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                _formatDate(event.eventDate),
                style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
              ),
              if (event.startTime != null) ...[
                const SizedBox(width: 15),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _formatTime(event.startTime!),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ],
          ),
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  event.location!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
