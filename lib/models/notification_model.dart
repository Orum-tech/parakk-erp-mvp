import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  homework,
  marks,
  attendance,
  leaveRequest,
  event,
  notice,
  message,
  fee,
  test,
  general,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationModel {
  final String notificationId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String userId; // Target user ID
  final String? relatedId; // Related entity ID (homework ID, test ID, etc.)
  final String? relatedType; // Type of related entity
  final Map<String, dynamic>? data; // Additional data
  final bool isRead;
  final DateTime? readAt;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.userId,
    this.relatedId,
    this.relatedType,
    this.data,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
  });

  String get typeString {
    switch (type) {
      case NotificationType.homework:
        return 'homework';
      case NotificationType.marks:
        return 'marks';
      case NotificationType.attendance:
        return 'attendance';
      case NotificationType.leaveRequest:
        return 'leaveRequest';
      case NotificationType.event:
        return 'event';
      case NotificationType.notice:
        return 'notice';
      case NotificationType.message:
        return 'message';
      case NotificationType.fee:
        return 'fee';
      case NotificationType.test:
        return 'test';
      default:
        return 'general';
    }
  }

  String get priorityString {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.homework:
        return Icons.assignment;
      case NotificationType.marks:
        return Icons.grade;
      case NotificationType.attendance:
        return Icons.calendar_today;
      case NotificationType.leaveRequest:
        return Icons.event_busy;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.notice:
        return Icons.campaign;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.fee:
        return Icons.payment;
      case NotificationType.test:
        return Icons.quiz;
      default:
        return Icons.notifications;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.homework:
        return Colors.orange;
      case NotificationType.marks:
        return Colors.purple;
      case NotificationType.attendance:
        return Colors.blue;
      case NotificationType.leaveRequest:
        return Colors.amber;
      case NotificationType.event:
        return Colors.green;
      case NotificationType.notice:
        return Colors.red;
      case NotificationType.message:
        return Colors.blueAccent;
      case NotificationType.fee:
        return Colors.deepPurple;
      case NotificationType.test:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _typeFromString(data['type'] ?? 'general'),
      priority: _priorityFromString(data['priority'] ?? 'normal'),
      userId: data['userId'] ?? '',
      relatedId: data['relatedId'],
      relatedType: data['relatedType'],
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'homework':
        return NotificationType.homework;
      case 'marks':
        return NotificationType.marks;
      case 'attendance':
        return NotificationType.attendance;
      case 'leaverequest':
        return NotificationType.leaveRequest;
      case 'event':
        return NotificationType.event;
      case 'notice':
        return NotificationType.notice;
      case 'message':
        return NotificationType.message;
      case 'fee':
        return NotificationType.fee;
      case 'test':
        return NotificationType.test;
      default:
        return NotificationType.general;
    }
  }

  static NotificationPriority _priorityFromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': typeString,
      'priority': priorityString,
      'userId': userId,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'data': data,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }
}
