import 'package:flutter/material.dart';
import '../../services/parent_service.dart';
import '../../models/notice_model.dart';

class NoticesScreen extends StatelessWidget {
  final String? classId;

  const NoticesScreen({super.key, this.classId});

  @override
  Widget build(BuildContext context) {
    final parentService = ParentService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Notices", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<NoticeModel>>(
        stream: parentService.getNotices(classId),
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

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No notices available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return _buildNoticeCard(notice, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice, BuildContext context) {
    Color typeColor;
    IconData typeIcon;

    switch (notice.noticeType) {
      case NoticeType.urgent:
        typeColor = Colors.red;
        typeIcon = Icons.priority_high;
        break;
      case NoticeType.academic:
        typeColor = Colors.blue;
        typeIcon = Icons.school;
        break;
      case NoticeType.event:
        typeColor = Colors.purple;
        typeIcon = Icons.event;
        break;
      case NoticeType.holiday:
        typeColor = Colors.orange;
        typeIcon = Icons.beach_access;
        break;
      case NoticeType.admin:
        typeColor = Colors.grey;
        typeIcon = Icons.admin_panel_settings;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: notice.noticeType == NoticeType.urgent
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice.noticeTypeString,
                      style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (notice.noticeType == NoticeType.urgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            notice.description,
            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
          ),
          if (notice.createdByName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  notice.createdByName!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatDate(notice.createdAt.toDate()),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
          if (notice.expiryDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.orange[600]),
                const SizedBox(width: 6),
                Text(
                  'Expires: ${_formatDate(notice.expiryDate!)}',
                  style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.w500),
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
