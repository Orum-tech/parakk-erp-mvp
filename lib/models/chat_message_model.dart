import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String message;
  final MessageType messageType;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime? readAt;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ChatMessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.message,
    required this.messageType,
    this.attachmentUrl,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatMessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      messageId: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      message: data['message'] ?? '',
      messageType: _typeFromString(data['messageType'] ?? 'text'),
      attachmentUrl: data['attachmentUrl'],
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  static MessageType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'messageType': messageType.toString().split('.').last,
      'attachmentUrl': attachmentUrl,
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  ChatMessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? message,
    MessageType? messageType,
    String? attachmentUrl,
    bool? isRead,
    DateTime? readAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  audio,
}
